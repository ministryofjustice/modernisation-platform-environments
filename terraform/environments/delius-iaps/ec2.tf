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

resource "aws_key_pair" "ec2-user" {
  key_name   = "ec2-user"
  public_key = file(".ssh/${terraform.workspace}/ec2-user.pub")
  tags = merge(
    local.tags,
    {
      Name = "ec2-user"
    }
  )
}

resource "aws_security_group" "iaps" {
  name        = lower(format("%s-%s", local.application_name, local.environment))
  description = "Controls access to IAPS EC2 instance"
  vpc_id      = data.aws_vpc.shared.id
  tags = merge(local.tags,
    { Name = lower(format("%s-%s", local.application_name, local.environment)) }
  )
}

resource "aws_security_group_rule" "ingress_traffic" {
  for_each          = local.application_data.iaps_sg_ingress_rules
  description       = format("Traffic for %s %d", each.value.protocol, each.value.from_port)
  from_port         = each.value.from_port
  protocol          = each.value.protocol
  security_group_id = aws_security_group.iaps.id
  to_port           = each.value.to_port
  type              = "ingress"
  cidr_blocks       = [data.aws_vpc.shared.cidr_block]
}

resource "aws_security_group_rule" "egress_traffic" {
  for_each          = local.application_data.iaps_sg_egress_rules
  description       = format("Outbound traffic for %s %d", each.value.protocol, each.value.from_port)
  from_port         = each.value.from_port
  protocol          = each.value.protocol
  security_group_id = aws_security_group.iaps.id
  to_port           = each.value.to_port
  type              = "egress"
  cidr_blocks       = [each.value.destination_cidr]
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
    actions   = ["s3:ListBucket"]
    resources = ["arn:aws:s3:::iaps-artifacts-*"]
  }

  statement {
    actions   = ["s3:GetObject"]
    resources = ["arn:aws:s3:::iaps-artifacts-*/*"]
  }
}

resource "aws_iam_role" "iaps_ec2_role" {
  name                = "iaps_ec2_role"
  assume_role_policy  = data.aws_iam_policy_document.iaps_ec2_assume_role_policy.json
  managed_policy_arns = ["arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"]
  inline_policy {
    policy = data.aws_iam_policy_document.iaps_ec2_policy.json
  }
  tags = merge(
    local.tags,
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

resource "aws_instance" "iaps" {
  ami                    = data.aws_ami.windows2022.id
  instance_type          = local.application_data.accounts[local.environment].ec2_iaps_instance_type
  vpc_security_group_ids = [aws_security_group.iaps.id]
  subnet_id              = data.aws_subnet.private_subnets_a.id
  monitoring             = true
  ebs_optimized          = true
  key_name               = aws_key_pair.ec2-user.key_name
  iam_instance_profile   = aws_iam_instance_profile.iaps_ec2_profile.id

  user_data = data.template_file.iaps_ec2_config.rendered

  metadata_options {
    http_endpoint = "enabled"
    http_tokens   = "required"
  }
  # Increase the volume size of the root volume
  root_block_device {
    volume_type = "gp3"
    volume_size = 50
    encrypted   = true
  }

  tags = merge(local.tags,
    { Name = lower(format("%s-%s", local.application_name, local.environment)) }
  )
  depends_on = [aws_security_group.iaps]
}