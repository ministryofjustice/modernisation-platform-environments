#--------------------------------------------------------------------------------
# Jumpserver

# Obtain your user password from the AWS Secrets Manager for your user e.g.
# /Jumpserver/Users/<your-github-username>
#--------------------------------------------------------------------------------

locals {

  ec2_jumpserver = {

    tags = {
      description = "nomis windows jumpserver"
      component   = "jumpserver"
    }

    instance = {
      disable_api_termination      = false
      instance_type                = "t3.medium"
      key_name                     = aws_key_pair.ec2-user.key_name
      monitoring                   = true
      metadata_options_http_tokens = "required"
      vpc_security_group_ids       = [aws_security_group.jumpserver-windows.id]
    }

    user_data_raw = base64encode(templatefile("./templates/jumpserver-user-data.yaml", { SECRET_PREFIX = local.secret_prefix, S3_BUCKET = module.s3-bucket.bucket.id }))

    autoscaling_group = {
      desired_capacity = 1
      max_size         = 1
      min_size         = 0
      force_delete     = true
    }
  }
}

module "ec2_jumpserver" {
  source = "./modules/ec2_autoscaling_group"


  providers = {
    aws.core-vpc = aws.core-vpc # core-vpc-(environment) holds the networking for all accounts
  }

  for_each = try(local.environment_config.ec2_jumpservers, {})

  name                  = each.key
  ami_name              = each.value.ami_name
  ami_owner             = try(each.value.ami_owner, "core-shared-services-production")
  instance              = merge(local.ec2_jumpserver.instance, lookup(each.value, "instance", {}))
  user_data_raw         = local.ec2_jumpserver.user_data_raw
  ebs_volume_config     = lookup(each.value, "ebs_volume_config", {})
  ebs_volumes           = lookup(each.value, "ebs_volumes", {})
  ssm_parameters_prefix = "jumpserver/"
  ssm_parameters        = {}
  autoscaling_group     = merge(local.ec2_jumpserver.autoscaling_group, lookup(each.value, "autoscaling_group", {}))
  autoscaling_schedules = coalesce(lookup(each.value, "autoscaling_schedules", null), {
    # if sizes not set, use the values defined in autoscaling_group
    "scale_up" = {
      recurrence = "0 7 * * Mon-Fri"
    }
    "scale_down" = {
      desired_capacity = lookup(each.value, "offpeak_desired_capacity", 0)
      recurrence       = "0 19 * * Mon-Fri"
    }
  })

  iam_resource_names_prefix = "ec2-jumpserver"
  instance_profile_policies = concat(local.ec2_common_managed_policies, [aws_iam_policy.jumpserver_users.arn])
  business_unit             = local.vpc_name
  application_name          = local.application_name
  environment               = local.environment
  region                    = local.region
  availability_zone         = local.availability_zone
  subnet_set                = local.subnet_set
  subnet_name               = "private"
  tags                      = merge(local.tags, local.ec2_jumpserver.tags, try(each.value.tags, {}))
  account_ids_lookup        = local.environment_management.account_ids
  ansible_repo              = "modernisation-platform-configuration-management"
  ansible_repo_basedir      = "ansible"
  branch                    = try(each.value.branch, "main")


}

#------------------------------------------------------------------------------
# Common Security Group for Jumpserver Instances
#------------------------------------------------------------------------------

# checkov:skip=CKV2_AWS_5:This is added via the module
resource "aws_security_group" "jumpserver-windows" {
  description = "Configure Windows jumpserver egress"
  name        = "jumpserver-windows-${local.application_name}"
  vpc_id      = local.vpc_id

  ingress {
    description = "access from Cloud Platform Prometheus server"
    from_port   = "9100"
    to_port     = "9100"
    protocol    = "TCP"
    cidr_blocks = [local.cidrs.cloud_platform]
  }

  egress {
    description = "allow all"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    #tfsec:ignore:aws-vpc-no-public-egress-sgr
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(
    local.tags,
    {
      Name = "jumpserver-commmon"
    }
  )
}

#------
# Jumpserver specific
#------

# IAM policy permissions to enable jumpserver to list secrets and get user passwords from secret manager
data "aws_iam_policy_document" "jumpserver_users" {

  # Allow getting secrets
  statement {
    sid    = "AllowGetSecret"
    effect = "Allow"
    actions = [
      "secretsmanager:GetSecretValue",
      "secretsmanager:DescribeSecret",
      "secretsmanager:ListSecretVersionIds",
    ]
    resources = [
      "arn:aws:secretsmanager:${local.region}:${data.aws_caller_identity.current.id}:secret:${local.secret_prefix}/*"
    ]
  }
  # Allow listing of secrets
  statement {
    sid    = "AllowListSecrets"
    effect = "Allow"
    actions = [
      "secretsmanager:ListSecrets",
    ]
    resources = [
      "*"
    ]
  }
}

# IAM policy for jumpserver_users
resource "aws_iam_policy" "jumpserver_users" {
  name        = "read-access-to-secrets"
  path        = "/"
  description = "Allow jumpserver to read and list secrets"
  policy      = data.aws_iam_policy_document.jumpserver_users.json
  tags = merge(
    local.tags,
    {
      Name = "read-access-to-secrets"
    }
  )
}


# create a password for each user in data.github_team.dso_users.members
resource "random_password" "jumpserver" {
  for_each    = toset(data.github_team.dso_users.members)
  length      = 32
  min_special = 5
  special     = true
}

# create empty secret in secret manager
# checkov:skip=CKV_AWS_149:coming back to this in DSOS-1587
resource "aws_secretsmanager_secret" "jumpserver" {
  for_each = toset(data.github_team.dso_users.members)
  name     = "${local.secret_prefix}/${each.value}"
  policy   = data.aws_iam_policy_document.jumpserver_secrets[each.value].json
  #kms_key_id              = data.aws_kms_key.general_shared.id
  recovery_window_in_days = 0
  tags = merge(
    local.tags,
    {
      Name = "jumpserver-user-${each.value}"
    },
  )
}

# populate secret with password
resource "aws_secretsmanager_secret_version" "jumpserver" {
  for_each      = random_password.jumpserver
  secret_id     = aws_secretsmanager_secret.jumpserver[each.key].id
  secret_string = each.value.result
}

# resource policy to restrict access to secret value to specific user and the CICD role used to deploy terraform
# checkov:skip=CKV_AWS_108:This is necessary, so just skip it
data "aws_iam_policy_document" "jumpserver_secrets" {
  for_each = toset(data.github_team.dso_users.members)

  statement {
    effect = "Allow"
    actions = [
      "secretsmanager:GetSecretValue",
      "secretsmanager:DescribeSecret",
      "secretsmanager:ListSecretVersionIds",
      "secretsmanager:ListSecrets",
    ]
    resources = ["*"]
    principals {
      type        = "AWS"
      identifiers = [data.aws_caller_identity.current.id]
    }
  }
}
