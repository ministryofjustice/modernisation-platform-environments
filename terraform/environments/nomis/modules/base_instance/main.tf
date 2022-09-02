data "aws_caller_identity" "current" {}

data "aws_ami" "base_ami" {
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

data "aws_vpc" "shared_vpc" {
  tags = {
    Name = "${var.business_unit}-${var.environment}"
  }
}

data "aws_subnet" "private" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.shared_vpc.id]
  }
  tags = {
    Name = "${var.business_unit}-${var.environment}-${var.subnet_set}-private-${var.region}*"
  }
}

#------------------------------------------------------------------------------
# EC2
#------------------------------------------------------------------------------

resource "aws_instance" "base_instance" {
  ami                         = data.aws_ami.base_ami.id
  associate_public_ip_address = false
  iam_instance_profile        = aws_iam_instance_profile.base_instance_profile.name
  instance_type               = var.instance_type
  key_name                    = var.key_name
  monitoring                  = false
  subnet_id                   = data.aws_subnet.private.id
  vpc_security_group_ids = [
    var.common_security_group_id,
    aws_security_group.base_instance
  ]
  #checkov:skip=CKV_AWS_79: We are tied to v1 metadata service
  metadata_options {
    http_endpoint = "enabled"
    http_tokens   = "required"
  }

  root_block_device {
    delete_on_termination = true
    encrypted             = true
    volume_type           = "gp3"

    tags = merge(
      var.tags,
      {
        Name = "base_instance-${var.name}-root-${data.aws_ami.base_ami.root_device_name}"
      }
    )
  }

  tags = merge(
    var.tags,
    {
      Name        = "base_instance-${var.name}"
      description = var.description
      os_type     = "Linux"
      os_version  = data.aws_ami.base_ami.tags["os-version"]
      always_on   = var.always_on
  })
}

#------------------------------------------------------------------------------
# Security Group
#------------------------------------------------------------------------------

resource "aws_security_group" "base_instance" {
  description = "Security group rules specific to this base instance"
  name        = "base_instance-${var.name}"
  vpc_id      = data.aws_vpc.shared_vpc.id

  tags = merge(
    var.tags,
    {
      Name = "base_instance-${var.name}",
  })
}

resource "aws_security_group_rule" "extra_rules" { # Extra ingress rules that might be specified
  for_each          = { for rule in var.extra_ingress_rules : "${rule.description}-${rule.to_port}" => rule }
  type              = "ingress"
  security_group_id = aws_security_group.base_instance.id
  description       = each.value.description
  from_port         = each.value.from_port
  to_port           = each.value.to_port
  cidr_blocks       = each.value.cidr_blocks
  protocol          = each.value.protocol
}

#------------------------------------------------------------------------------
# Instance profile to be assumed by the ec2 instances
#------------------------------------------------------------------------------

resource "aws_iam_role" "base_instance_role" {
  name                 = "ec2-base_instance-role-${var.name}"
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
      Name = "ec2-base_instance-role-${var.name}"
    }
  )
}

resource "aws_iam_instance_profile" "base_instance_profile" {
  name = "ec2-base_instance-profile-${var.name}"
  role = aws_iam_role.base_instance_role.name
}
