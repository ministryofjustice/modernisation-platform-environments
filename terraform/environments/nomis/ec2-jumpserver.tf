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
  owners      = [local.environment_management.account_ids["core-shared-services-production"]] #["801119661308"] # Microsoft

  filter {
    name   = "name"
    values = ["nomis_jumpserver_2022-06-15*"]
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
  #checkov:skip=CKV_AWS_126: "Ensure that detailed monitoring is enabled for EC2 instances" don't think we need such fine resolution for JS
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
#tfsec:ignore:aws-ssm-secret-use-customer-key
resource "aws_secretsmanager_secret" "jumpserver_users" {
  #checkov:skip=CKV_AWS_149: "Ensure that Secrets Manager secret is encrypted using KMS CMK"
  for_each                = toset(local.jumpserver_users)
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