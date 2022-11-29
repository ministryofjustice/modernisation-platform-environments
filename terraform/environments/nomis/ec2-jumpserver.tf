#--------------------------------------------------------------------------------
# Jumpserver
# This is not in use YET as we are still using the old ec2-jumpserver.tf file
# Once the password rotation is worked out we can switch to this new version as
# it uses the ec2_autoscaling_group module
#
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
  instance_profile_policies = concat(local.ec2_common_managed_policies, [aws_iam_policy.secret_access_jumpserver.arn])
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

#------
# Jumpserver specific
#------
resource "aws_iam_instance_profile" "jumpserver" {
  name = "ec2-jumpserver-profil"
  role = aws_iam_role.jumpserver.name
  path = "/"
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

# IAM role for jumpserver instances
resource "aws_iam_policy" "secret_access_jumpserver" {
  name        = "read-access-to-secret-store"
  path        = "/"
  description = "Policy for read access to secret store"
  policy      = data.aws_iam_policy_document.jumpserver_users.json
  tags = merge(
    local.tags,
    {
      Name = "read-access-to-secret-store"
    },
  )
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
