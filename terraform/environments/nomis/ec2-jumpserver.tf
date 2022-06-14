#------------------------------------------------------------------------------
# Windows Jumpserver
# To add a new local user account, add a github username to `jumpserver_users`
# local variable.  Scheduled job running on instance will create user and push 
# password to Secrets Manager, which only said user can access.
#------------------------------------------------------------------------------

locals {
  jumpserver_users = [ # must be github username
    "rwhittlemoj",
    "julialawrence",
    "ewastempel",
    "jnq"
  ]
  secret_prefix = "/Jumpserver/Users"
}

data "aws_subnet" "private_az_a" {
  tags = {
    Name = "${local.vpc_name}-${local.environment}-${local.subnet_set}-private-${local.region}a"
  }
}

data "aws_ami" "jumpserver_image" {
  most_recent = true
  owners      = ["801119661308"] # Microsoft

  filter {
    name   = "name"
    values = ["Windows_Server-2022-English-Full-Base-2022.05.25"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

# user-data template
data "template_file" "user_data" {
  template = file("./templates/jumpserver-user-data.yaml")
  vars = {
    SECRET_PREFIX = local.secret_prefix
    S3_BUCKET     = module.s3-bucket.bucket.id
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
  user_data                   = data.template_file.user_data.rendered
  user_data_replace_on_change = true
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
      Name          = "jumpserver_windows"
      os_type       = "Windows"
      os_version    = "2019"
      always_on     = "false"
      "Patch Group" = "${aws_ssm_patch_group.windows.patch_group}"
    }
  )
}

resource "aws_security_group" "jumpserver-windows" {
  # this skip check can be removed once the jumpserver is reinstated
  # reluctant to delete the SG as its referenced in various places
  #checkov:skip=CKV2_AWS_5: "Ensure that Security Groups are attached to another resource"
  description = "Configure Windows jumpserver egress"
  name        = "jumpserver-windows-${local.application_name}"
  vpc_id      = local.vpc_id

  ingress {
    description = "access from Cloud Platform Prometheus server"
    from_port   = "9182"
    to_port     = "9182"
    protocol    = "TCP"
    cidr_blocks = [local.accounts[local.environment].database_external_access_cidr.cloud_platform]
  }

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

# create empty secret in secret manager
resource "aws_secretsmanager_secret" "jumpserver_users" {
  for_each = toset(local.jumpserver_users)
  name     = "${local.secret_prefix}/${each.value}"
  policy   = data.aws_iam_policy_document.jumpserver_secrets[each.value].json
  recovery_window_in_days = 0
  tags = merge(
    local.tags,
    {
      Name = "jumpserver-user-${each.value}"
    },
  )
}

# resource policy to restrict access to secret value to specific user and the CICD role used to deploy terraform
data "aws_iam_policy_document" "jumpserver_secrets" {
  for_each = toset(local.jumpserver_users)
  statement {
    effect    = "Deny"
    actions   = ["secretsmanager:GetSecretValue"]
    resources = ["*"]
    principals {
      type        = "*"
      identifiers = ["*"]
    }
    condition {
      test     = "StringNotLike"
      variable = "aws:userid"
      values = [
        "*:${each.value}@digital.justice.gov.uk",                       # specific user
        "${data.aws_iam_role.member_infrastructure_access.unique_id}:*" # terraform CICD role
      ]
    }
  }
}

# IAM policy permissions to enable jumpserver to list secrets and put user passwords into secret manager
data "aws_iam_policy_document" "jumpserver_users" {
  statement {
    effect    = "Allow"
    actions   = ["secretsmanager:PutSecretValue"]
    resources = ["arn:aws:secretsmanager:${local.region}:${data.aws_caller_identity.current.id}:secret:${local.secret_prefix}/*"]
  }
  statement {
    effect    = "Allow"
    actions   = ["secretsmanager:ListSecrets"]
    resources = ["*"]
  }
}

# Add policy to role
resource "aws_iam_role_policy" "jumpserver_users" {
  name   = "secrets-access-jumpserver-users"
  role   = aws_iam_role.ec2_jumpserver_role.id
  policy = data.aws_iam_policy_document.jumpserver_users.json
}



# Create an empty parameter for Adminstrator password recovery using
# AWSSupport-RunEC2RescueForWindowsTool Systems Manager Run Command
# https://docs.aws.amazon.com/AWSEC2/latest/WindowsGuide/ec2rw-ssm.html
# Pre-creating it so it gets deleted with the instance

# resource "aws_ssm_parameter" "jumpserver_ec2_rescue" {
#   name        = "/EC2Rescue/Passwords/${aws_instance.jumpserver_windows.id}"
#   description = "Jumpserver local admin password"
#   type        = "SecureString"
#   value       = "default"

#   tags = merge(
#     local.tags,
#     {
#       Name = "jumpserver-admin-password"
#     }
#   )
#   lifecycle {
#     # ignore changes to value and description as will get updated by Systems Manager automation
#     ignore_changes = [
#       value,
#       description
#     ]
#   }
# }

# data "aws_iam_policy_document" "jumpserver_put_parameter" {
#   statement {
#     effect = "Allow"
#     actions = [
#       "ssm:PutParameter",
#     ]
#     resources = [aws_ssm_parameter.jumpserver_ec2_rescue.arn]
#   }
# }

# resource "aws_iam_role_policy" "jumpserver_put_parameter" {
#   name   = "jumpserver-parameter-access"
#   role   = aws_iam_role.ec2_jumpserver_role.id
#   policy = data.aws_iam_policy_document.jumpserver_put_parameter.json
# }

# # Automation to recover password to parameter store on instance creation
# resource "aws_ssm_association" "jumpserver_ec2_rescue" {
#   name             = "AWSSupport-RunEC2RescueForWindowsTool"
#   association_name = "jumpserver-ec2-rescue"
#   parameters = {
#     Command = "ResetAccess"
#   }
#   targets {
#     key    = "InstanceIds"
#     values = [aws_instance.jumpserver_windows.id]
#   }
#   depends_on = [
#     aws_iam_role_policy.jumpserver_put_parameter,
#     aws_ssm_parameter.jumpserver_ec2_rescue
#   ]
# }
