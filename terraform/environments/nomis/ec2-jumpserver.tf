#------------------------------------------------------------------------------
# Jumpserver
#------------------------------------------------------------------------------

locals {

  secret_prefix_asg = "/Jumpserver-Asg/Users"

  ec2_jumpserver = {
    
    tags = {
      description = "nomis windows jumpserver"
      component   = "jumpserver"
    }

    instance = {
      disable_api_termination      = false
      instance_type                = "t3.medium"
      key_name                     = aws_key_pair.ec2-user.key_name
      monitoring                   = false
      metadata_options_http_tokens = "required"
      vpc_security_group_ids       = [aws_security_group.jumpserver-windows.id]
    }

    user_data_raw = base64encode(templatefile("./templates/jumpserver-user-data.yaml", { SECRET_PREFIX = local.secret_prefix_asg, S3_BUCKET = module.s3-bucket.bucket.id }))

    autoscaling_group = {  
      desired_capacity = 1
      max_size         = 2
      min_size         = 0
      force_delete     = true
    }
  }
}

module "ec2_jumpserver_autoscaling_group" {
  source = "./modules/ec2_autoscaling_group"

  
  providers = {
    aws.core-vpc = aws.core-vpc # core-vpc-(environment) holds the networking for all accounts
  }

  for_each = try(local.environment_config.ec2_jumpserver_autoscaling_groups, {})

  name                  = each.key
  ami_name              = each.value.ami_name
  ami_owner             = try(each.value.ami_owner, "core-shared-services-production")
  instance              = merge(local.ec2_jumpserver.instance, lookup(each.value, "instance", {}))
  user_data_raw         = local.ec2_jumpserver.user_data_raw
  ebs_volume_config  = lookup(each.value, "ebs_volume_config", {})
  ebs_volumes        = lookup(each.value, "ebs_volumes", {})
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

  iam_resource_names_prefix = "ec2-jumpserver-asg"
  instance_profile_policies = concat(local.ec2_common_managed_policies, [aws_iam_policy.secret_access_jumpserver_asg.arn])
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

# required as part of the user manager setup
data "github_team" "jumpserver" {
  slug = "studio-webops"
}

# resource policy to restrict access to secret value to specific user and the CICD role used to deploy terraform
data "aws_iam_policy_document" "jumpserver_secrets_asg" {
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

#------
# Jumpserver specific
#------
resource "aws_iam_instance_profile" "jumpserver_asg" {
  name = "ec2-jumpserver-profile-asg"
  role = aws_iam_role.jumpserver_asg.name
  path = "/"
}

# create empty secret in secret manager
#tfsec:ignore:aws-ssm-secret-use-customer-key
resource "aws_secretsmanager_secret" "jumpserver_asg" {
  #checkov:skip=CKV_AWS_149: "Ensure that Secrets Manager secret is encrypted using KMS CMK"
  for_each                = toset(data.github_team.jumpserver.members)
  name                    = "${local.secret_prefix_asg}/${each.value}"
  policy                  = data.aws_iam_policy_document.jumpserver_secrets_asg[each.value].json
  recovery_window_in_days = 0
  tags = merge(
    local.tags,
    {
      Name = "jumpserver-user-${each.value}"
    },
  )
}

# IAM policy permissions to enable jumpserver to list secrets and put user passwords into secret manager
data "aws_iam_policy_document" "jumpserver_users_asg" {
  statement {
    effect    = "Allow"
    actions   = ["secretsmanager:PutSecretValue"]
    resources = ["arn:aws:secretsmanager:${local.region}:${data.aws_caller_identity.current.id}:secret:${local.secret_prefix_asg}/*"]
  }
  statement {
    effect    = "Allow"
    actions   = ["secretsmanager:ListSecrets"]
    resources = ["*"]
  }
}

# Add policy to role NOTE: removed
/* resource "aws_iam_role_policy" "jumpserver_users_asg" {
  name   = "secrets-access-jumpserver-users-asg"
  role   = aws_iam_role.jumpserver_asg.id
  policy = data.aws_iam_policy_document.jumpserver_users_asg.json
} */

# IAM role for jumpserver instances
resource "aws_iam_policy" "secret_access_jumpserver_asg" {
  name        = "write-access-to-secret-store"
  path        = "/"
  description = "Policy for access to secret store"
  policy      = data.aws_iam_policy_document.jumpserver_users_asg.json
  tags = merge(
    local.tags,
    {
      Name = "write-access-to-secret-store"
    },
  )
}

# NOTE: removed
resource "aws_iam_role" "jumpserver_asg" {
  name                 = "ec2-jumpserver-role-asg"
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
      Name = "ec2-jumpserver-role-asg"
    },
  )
}

/* output "debug" {
  value = module.ec2_jumpserver_autoscaling_group.value.0
  sensitive = true
}   */
