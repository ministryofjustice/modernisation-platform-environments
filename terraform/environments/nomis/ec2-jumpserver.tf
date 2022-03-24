#------------------------------------------------------------------------------
# Windows Jumpserver
#------------------------------------------------------------------------------

data "aws_subnet" "private_az_a" {
  tags = {
    Name = "${local.vpc_name}-${local.environment}-${local.subnet_set}-private-${local.region}a"
  }
}

data "aws_ami" "jumpserver_image" {
  most_recent = true
  owners      = ["self"]

  filter {
    name   = "name"
    values = ["jumpserver-windows"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

resource "aws_instance" "jumpserver_windows" {
  instance_type               = "t3.medium"
  ami                         = data.aws_ami.jumpserver_image.id
  associate_public_ip_address = false
  iam_instance_profile        = aws_iam_instance_profile.ec2_jumpserver_profile.id
  ebs_optimized               = true
  monitoring                  = false
  vpc_security_group_ids      = [aws_security_group.jumpserver-windows.id]
  subnet_id                   = data.aws_subnet.private_az_a.id
  key_name                    = aws_key_pair.ec2-user.key_name
  metadata_options {
    http_endpoint = "enabled"
    http_tokens   = "required"
  }
  root_block_device {
    delete_on_termination = true
    encrypted             = true
    volume_type           = "gp3"
  }

  tags = merge(
    local.tags,
    {
      Name       = "jumpserver_windows"
      os_type    = "Windows"
      os_version = "2019"
      always_on  = "false"
    }
  )
}

resource "aws_security_group" "jumpserver-windows" {
  description = "Configure Windows jumpserver egress"
  name        = "jumpserver-windows-${local.application_name}"
  vpc_id      = local.vpc_id
  egress {
    description = "allow all"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    #tfsec:ignore:aws-vpc-no-public-egress-sgr
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_iam_role" "ec2_jumpserver_role" {
  name                 = "ec2-jumpserver-role"
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
  managed_policy_arns = local.ec2_common_managed_policies
  tags = merge(
    local.tags,
    {
      Name = "ec2-jumpserver-role"
    },
  )
}

resource "aws_iam_instance_profile" "ec2_jumpserver_profile" {
  name = "ec2-jumpserver-profile"
  role = aws_iam_role.ec2_jumpserver_role.name
  path = "/"
}

# Create an empty parameter for password recovery using
# AWSSupport-RunEC2RescueForWindowsTool Systems Manager Run Command
# https://docs.aws.amazon.com/AWSEC2/latest/WindowsGuide/ec2rw-ssm.html
# Pre-creating it so it gets deleted with the instance

resource "aws_ssm_parameter" "jumpserver_ec2_rescue" {
  name        = "/EC2Rescue/Passwords/${aws_instance.jumpserver_windows.id}"
  description = "Jumpserver local admin password"
  type        = "SecureString"
  value       = "default"

  tags = merge(
    local.tags,
    {
      Name = "jumpserver-admin-password"
    }
  )
  lifecycle {
    # ignore changes to value as will get updated by Systems Manager automation
    ignore_changes = [value]
  }
}

data "aws_iam_policy_document" "jumpserver_put_parameter" {
  statement {
    effect = "Allow"
    actions = [
      "ssm:PutParameter",
    ]
    resources = [aws_ssm_parameter.jumpserver_ec2_rescue.arn]
  }
}

resource "aws_iam_role_policy" "jumpserver_put_parameter" {
  name   = "jumpserver-parameter-access"
  role   = aws_iam_role.ec2_jumpserver_role.id
  policy = data.aws_iam_policy_document.jumpserver_put_parameter.json
}

# Automation to recover password to parameter store on instance creation
resource "aws_ssm_association" "jumpserver_ec2_rescue" {
  name             = "AWSSupport-RunEC2RescueForWindowsTool"
  association_name = "jumpserver-ec2-rescue"
  parameters = {
    Command = "ResetAccess"
  }
  targets {
    key    = "InstanceIds"
    values = [aws_instance.jumpserver_windows.id]
  }
  depends_on = [
    aws_iam_role_policy.jumpserver_put_parameter,
    aws_ssm_parameter.jumpserver_ec2_rescue
  ]
}