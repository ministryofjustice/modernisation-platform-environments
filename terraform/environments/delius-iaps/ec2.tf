##
# Local vars for ec2
##
locals {
  ec2_tags = merge(local.tags, {
    Name = lower(format("%s-%s", local.application_name, local.environment))
    }
  )
}

##
# Data
## 
data "aws_ami" "windows2022" {
  most_recent = true

  filter {
    name   = "name"
    values = ["Windows_Server-2022-English-Full-Base-2022.*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  owners = ["801119661308"] # AWS
}

##
# Resources
##
resource "aws_key_pair" "ec2-user" {
  key_name   = "ec2-user"
  public_key = file(".ssh/${terraform.workspace}/ec2-user.pub")
  tags = merge(
    local.ec2_tags,
    {
      Name = "ec2-user"
    }
  )
}

resource "aws_security_group" "iaps" {
  name        = lower(format("%s-%s", local.application_name, local.environment))
  description = "Controls access to IAPS EC2 instance"
  vpc_id      = data.aws_vpc.shared.id
  tags        = local.ec2_tags
}

resource "aws_security_group_rule" "ingress_traffic_vpc" {
  for_each          = local.application_data.iaps_sg_ingress_rules_vpc
  description       = format("Traffic for %s %d", each.value.protocol, each.value.from_port)
  from_port         = each.value.from_port
  protocol          = each.value.protocol
  security_group_id = aws_security_group.iaps.id
  to_port           = each.value.to_port
  type              = "ingress"
  cidr_blocks       = [data.aws_vpc.shared.cidr_block]
}

resource "aws_security_group_rule" "egress_traffic_cidr" {
  for_each          = local.application_data.iaps_sg_egress_rules_cidr
  description       = format("Outbound traffic for %s %d", each.value.protocol, each.value.from_port)
  from_port         = each.value.from_port
  protocol          = each.value.protocol
  security_group_id = aws_security_group.iaps.id
  to_port           = each.value.to_port
  type              = "egress"
  cidr_blocks       = [each.value.destination_cidr]
}

resource "aws_security_group_rule" "egress_traffic_ad" {
  for_each                 = local.application_data.iaps_sg_egress_rules_ad
  description              = format("Outbound traffic for %s %d", each.value.protocol, each.value.from_port)
  from_port                = each.value.from_port
  protocol                 = each.value.protocol
  security_group_id        = aws_security_group.iaps.id
  to_port                  = each.value.to_port
  type                     = "egress"
  source_security_group_id = aws_directory_service_directory.active_directory.security_group_id
}

data "aws_iam_policy_document" "iaps_ec2_assume_role_policy" {
  statement {
    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
    actions = ["sts:AssumeRole"]
  }
}

data "aws_iam_policy_document" "iaps_ec2_policy" {
  statement {
    sid       = "BucketPermissions"
    actions   = ["s3:ListBucket"]
    resources = ["arn:aws:s3:::${local.artefact_bucket_name}"]
  }

  statement {
    sid       = "ObjectPermissions"
    actions   = ["s3:GetObject"]
    resources = ["arn:aws:s3:::${local.artefact_bucket_name}/*"]
  }

   statement {
    sid       = "SecretPermissions"
    actions   = [
      "secretsmanager:GetSecretValue"
    ]
    resources = [aws_secretsmanager_secret.ad_password.arn]
  }
}

resource "aws_iam_role" "iaps_ec2_role" {
  name                = "iaps_ec2_role"
  assume_role_policy  = data.aws_iam_policy_document.iaps_ec2_assume_role_policy.json
  managed_policy_arns = ["arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"]
  inline_policy {
    name   = "IapsEc2Policy"
    policy = data.aws_iam_policy_document.iaps_ec2_policy.json
  }
  tags = merge(
    local.ec2_tags,
    {
      Name = "iaps_ec2_role"
    },
  )
}

resource "aws_iam_instance_profile" "iaps_ec2_profile" {
  name = "iaps_ec2_profile"
  role = aws_iam_role.iaps_ec2_role.name
}

data "template_file" "iaps_ec2_config" {
  template = file("${path.module}/templates/iaps-EC2LaunchV2.yaml.tpl")
  vars = {

  }
}

resource "aws_launch_template" "iaps_instance_launch_template" {
  # Basic options
  name                   = "iaps-launch-template"
  image_id               = data.aws_ami.windows2022.id
  instance_type          = local.application_data.accounts[local.environment].ec2_iaps_instance_type
  key_name               = aws_key_pair.ec2-user.key_name
  vpc_security_group_ids = [aws_security_group.iaps.id]
  user_data              = base64encode(data.template_file.iaps_ec2_config.rendered)

  iam_instance_profile {
    name = aws_iam_instance_profile.iaps_ec2_profile.id
  }

  # Monitoring
  monitoring {
    enabled = true
  }
  metadata_options {
    http_endpoint = "enabled"
    http_tokens   = "required"
  }

  # Storage
  ebs_optimized = true
  block_device_mappings {
    device_name = "/dev/sda1"
    ebs {
      volume_type           = "gp3"
      volume_size           = 50
      encrypted             = true
      delete_on_termination = true
    }
  }

  # Tags
  dynamic "tag_specifications" {
    for_each = toset(local.application_data.launch_template_tag_resource_types)
    content {
      resource_type = tag_specifications.key # relevant resources in this use case (see https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/launch_template#tag_specifications)
      tags          = local.ec2_tags
    }
  }
}

resource "aws_autoscaling_group" "iaps_instance_asg" {
  name_prefix               = "iaps-instance-"
  min_size                  = 1
  max_size                  = 1
  desired_capacity          = 1
  vpc_zone_identifier       = data.aws_subnets.private-public.ids
  health_check_grace_period = 300
  health_check_type         = "EC2"
  launch_template {
    id      = aws_launch_template.iaps_instance_launch_template.id
    version = "$Latest"
  }
  dynamic "tag" {
    for_each = local.ec2_tags
    content {
      key                 = tag.key
      value               = tag.value
      propagate_at_launch = true
    }

  }
}
