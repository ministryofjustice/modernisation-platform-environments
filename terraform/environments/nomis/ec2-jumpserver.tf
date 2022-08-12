#------------------------------------------------------------------------------
# Windows Jumpserver
# To add a new local user account, add a github username to `jumpserver_users`
# local variable.  Scheduled job running on instance will create user and push
# password to Secrets Manager, which only said user can access.
#------------------------------------------------------------------------------

locals {
  secret_prefix = "/Jumpserver/Users"
}

data "github_team" "jumpserver" {
  slug = "studio-webops"
}

data "aws_vpc" "jumpserver" {
  tags = {
    Name = "${local.vpc_name}-${local.environment}"
  }
}
data "aws_subnets" "jumpserver" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.jumpserver.id]
  }
  tags = {
    Name = "${local.vpc_name}-${local.environment}-${local.subnet_set}-private-${local.region}*"
  }
}

data "aws_ami" "jumpserver" {
  most_recent = true
  owners      = [local.environment_management.account_ids["core-shared-services-production"]]

  filter {
    name   = "name"
    values = ["nomis_jumpserver_2022-06-21*"]
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

# instance launch template
resource "aws_launch_template" "jumpserver" {
  image_id                             = data.aws_ami.jumpserver.id
  instance_initiated_shutdown_behavior = "terminate"
  instance_type                        = "t3.medium"
  key_name                             = aws_key_pair.ec2-user.key_name
  iam_instance_profile {
    arn = aws_iam_instance_profile.jumpserver.arn
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
    security_groups             = [aws_security_group.jumpserver-windows.id]
    delete_on_termination       = true
  }

  user_data = base64encode(data.template_file.user_data.rendered)
  tag_specifications {
    resource_type = "instance"
    tags = merge(
      local.tags,
      {
        Name          = "jumpserver_windows"
        os_type       = "Windows"
        os_version    = "2022"
        always_on     = "false"
        "Patch Group" = aws_ssm_patch_group.windows.patch_group
      }
    )
  }
}

# autoscaling
resource "aws_autoscaling_group" "jumpserver" {
  launch_template {
    id      = aws_launch_template.jumpserver.id
    version = "$Default"
  }
  desired_capacity    = 1
  name                = "jumpserver-autoscaling-group"
  min_size            = 1
  max_size            = 1
  force_delete        = true
  vpc_zone_identifier = data.aws_subnets.jumpserver.ids
  tag {
    key                 = "Name"
    value               = "jumpserver"
    propagate_at_launch = true
  }
}
resource "aws_autoscaling_schedule" "scale_up" {
  scheduled_action_name  = "jumpserver_scale_up"
  min_size               = 0
  max_size               = 1
  desired_capacity       = 1
  recurrence             = "0 7 * * Mon-Fri"
  autoscaling_group_name = aws_autoscaling_group.jumpserver.name
}

resource "aws_autoscaling_schedule" "scale_down" {
  scheduled_action_name  = "jumpserver_scale_down"
  min_size               = 0
  max_size               = 0
  desired_capacity       = 0
  recurrence             = "0 19 * * Mon-Fri"
  autoscaling_group_name = aws_autoscaling_group.jumpserver.name
}
resource "aws_security_group" "jumpserver-windows" {
  description = "Configure Windows jumpserver egress"
  name        = "jumpserver-windows-${local.application_name}"
  vpc_id      = local.vpc_id

  ingress {
    description = "access from Cloud Platform Prometheus server"
    from_port   = "9100"
    to_port     = "9100"
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

resource "aws_iam_role" "jumpserver" {
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

resource "aws_iam_instance_profile" "jumpserver" {
  name = "ec2-jumpserver-profile"
  role = aws_iam_role.jumpserver.name
  path = "/"
}

# create empty secret in secret manager
#tfsec:ignore:aws-ssm-secret-use-customer-key
resource "aws_secretsmanager_secret" "jumpserver" {
  #checkov:skip=CKV_AWS_149: "Ensure that Secrets Manager secret is encrypted using KMS CMK"
  for_each                = toset(data.github_team.jumpserver.members)
  name                    = "${local.secret_prefix}/${each.value}"
  policy                  = data.aws_iam_policy_document.jumpserver_secrets[each.value].json
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
  for_each = toset(data.github_team.jumpserver.members)
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
  role   = aws_iam_role.jumpserver.id
  policy = data.aws_iam_policy_document.jumpserver_users.json
}
