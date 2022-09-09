data "aws_caller_identity" "current" {}

data "aws_ami" "this" {
  most_recent = true
  owners      = [var.ami_owner]

  filter {
    name   = "name"
    values = [var.ami_name]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

data "aws_vpc" "this" {
  tags = {
    Name = "${var.business_unit}-${var.environment}"
  }
}

data "aws_subnets" "this" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.this.id]
  }
  tags = {
    Name = "${var.business_unit}-${var.environment}-${var.subnet_set}-${var.subnet_type}-${var.region}*"
  }
}

#------------------------------------------------------------------------------
# Security Group
#------------------------------------------------------------------------------

resource "aws_security_group" "this" {
  description = "Security group rules specific to this base instance"
  name        = "base_instance_asg-${var.name}"
  vpc_id      = data.aws_vpc.this.id

  tags = merge(
    var.tags,
    {
      Name = "base_instance-${var.name}",
  })
}

resource "aws_security_group_rule" "extra_rules" { # Extra ingress rules that might be specified
  for_each          = { for rule in var.extra_ingress_rules : "${rule.description}-${rule.to_port}" => rule }
  type              = "ingress"
  security_group_id = aws_security_group.this.id
  description       = each.value.description
  from_port         = each.value.from_port
  to_port           = each.value.to_port
  cidr_blocks       = each.value.cidr_blocks
  protocol          = each.value.protocol
}

#------------------------------------------------------------------------------
# Instance profile to be assumed by the ec2 instances
#------------------------------------------------------------------------------

resource "aws_iam_role" "this" {
  name                 = "ec2-base_instance-asg-role-${var.name}"
  path                 = "/"
  max_session_duration = "3600"
  assume_role_policy = jsonencode(
    {
      "Version" : "2012-10-17",
      "Statement" : [
        {
          "Effect" : "Allow",
          "Principal" : {
            "Service" : "ec2.amazonaws.com"
          }
          "Action" : "sts:AssumeRole",
          "Condition" : {}
        }
      ]
    }
  )

  managed_policy_arns = var.instance_profile_policies

  tags = merge(
    var.tags,
    {
      Name = "ec2-base_instance-asg-role-asg-${var.name}"
    }
  )
}

resource "aws_iam_instance_profile" "this" {
  name = "ec2-base_instance-asg-profile-${var.name}"
  role = aws_iam_role.this.name
}

resource "aws_launch_template" "this" {
  name                                 = "${var.name}-${var.application_name}-${var.environment}"
  image_id                             = data.aws_ami.this.id
  instance_initiated_shutdown_behavior = "terminate"
  instance_type                        = var.instance_type
  key_name                             = var.key_name
  ebs_optimized                        = true

  block_device_mappings {
    device_name = data.aws_ami.this.root_device_name
    ebs {
      delete_on_termination = true
      encrypted             = true
      volume_type           = "gp3"
    }
  }
  iam_instance_profile {
    arn = aws_iam_instance_profile.this.arn
  }
  metadata_options {
    http_endpoint = "enabled"
    http_tokens   = "required"
  }

  monitoring {
    enabled = false
  }

  network_interfaces {
    associate_public_ip_address = false
    security_groups             = [var.common_security_group_id, aws_security_group.this.id]
    delete_on_termination       = true
  }

  tag_specifications {
    resource_type = "instance"
    tags = merge(
      var.tags,
      {
        Name        = "base_instance-${var.name}"
        description = var.description
        os_type     = "Linux"
        os_version  = lookup(data.aws_ami.this.tags, "os-version", null)
        always_on   = var.always_on
    })
  }

  tag_specifications {
    resource_type = "volume"
    tags = merge(
      var.tags,
      {
        Name = "base_instance-${var.name}-root-${data.aws_ami.this.root_device_name}"
      }
    )
  }

}

# autoscaling
resource "aws_autoscaling_group" "this" {
  launch_template {
    id = aws_launch_template.this.id
  }
  desired_capacity    = 1
  name                = "base_instance-${var.name}-${var.application_name}-${var.environment}"
  min_size            = 1
  max_size            = 1
  force_delete        = true
  vpc_zone_identifier = data.aws_subnets.this.ids
  tag {
    key                 = "Name"
    value               = "base_instance-${var.name}-${var.application_name}-${var.environment}"
    propagate_at_launch = true
  }
  depends_on = [
    aws_launch_template.this
  ]
}
resource "aws_autoscaling_schedule" "scale_up" {
  scheduled_action_name  = "base_instance-${var.name}_scale_up"
  min_size               = 0
  max_size               = 1
  desired_capacity       = 1
  recurrence             = "0 7 * * Mon-Fri"
  autoscaling_group_name = aws_autoscaling_group.this.name
}

resource "aws_autoscaling_schedule" "scale_down" {
  scheduled_action_name  = "base_instance-${var.name}_scale_down"
  min_size               = 0
  max_size               = 0
  desired_capacity       = 0
  recurrence             = "0 19 * * Mon-Fri"
  autoscaling_group_name = aws_autoscaling_group.this.name
}
