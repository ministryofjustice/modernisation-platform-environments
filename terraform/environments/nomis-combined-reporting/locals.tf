# define configuration common to all environments here
# define environment specific configuration in locals_development.tf, locals_test.tf etc.

locals {
  baseline_presets_environments_specific = {
    development   = local.baseline_presets_development
    test          = local.baseline_presets_test
    preproduction = local.baseline_presets_preproduction
    production    = local.baseline_presets_production
  }
  baseline_presets_environment_specific = local.baseline_presets_environments_specific[local.environment]

  baseline_environments_specific = {
    development   = local.baseline_development
    test          = local.baseline_test
    preproduction = local.baseline_preproduction
    production    = local.baseline_production
  }
  baseline_environment_specific = local.baseline_environments_specific[local.environment]

  baseline_presets_all_environments = {
    options = {
      db_backup_bucket_name                       = "ncr-db-backup-bucket"
      enable_backup_plan_daily_and_weekly         = true
      enable_business_unit_kms_cmks               = true
      enable_image_builder                        = true
      enable_ec2_cloud_watch_agent                = true
      enable_ec2_self_provision                   = true
      enable_ec2_oracle_enterprise_managed_server = true
      enable_ec2_user_keypair                     = true
      enable_s3_bucket                            = true
      enable_s3_db_backup_bucket                  = true
      enable_s3_software_bucket                   = true
      iam_policies_filter                         = ["ImageBuilderS3BucketWriteAndDeleteAccessPolicy"]
      iam_policies_ec2_default                    = ["EC2S3BucketWriteAndDeleteAccessPolicy", "ImageBuilderS3BucketWriteAndDeleteAccessPolicy"]
      s3_iam_policies                             = ["EC2S3BucketWriteAndDeleteAccessPolicy"]
    }
  }

  baseline_all_environments = {
    iam_policies = {
      SasTokenRotatorPolicy = {
        description = "Allows updating of secrets in SSM"
        statements = [
          {
            sid    = "RotateSecrets"
            effect = "Allow"
            actions = [
              "ssm:PutParameter",
            ]
            resources = [
              "arn:aws:ssm:*:*:parameter/azure/*",
            ]
          },
          {
            sid    = "EncryptSecrets"
            effect = "Allow"
            actions = [
              "kms:Encrypt",
            ]
            resources = [
              data.aws_kms_key.general_shared.arn,
            ]
          },
        ]
      }
    }

    iam_roles = {
      SasTokenRotatorRole = {
        assume_role_policy = [{
          effect  = "Allow"
          actions = ["sts:AssumeRoleWithWebIdentity"]
          principals = {
            type        = "Federated"
            identifiers = ["arn:aws:iam::${data.aws_caller_identity.current.account_id}:oidc-provider/token.actions.githubusercontent.com"]
          }
          conditions = [
            {
              test     = "StringEquals"
              values   = ["sts.amazonaws.com"]
              variable = "token.actions.githubusercontent.com:aud"
            },
            {
              test     = "StringLike"
              values   = ["repo:ministryofjustice/dso-modernisation-platform-automation:*"] # ["repo:ministryofjustice/dso-modernisation-platform-automation:ref:refs/heads/main"]
              variable = "token.actions.githubusercontent.com:sub"
            },
          ]
        }]
        policy_attachments = [
          "SasTokenRotatorPolicy",
        ]
      }
    }

    security_groups = local.security_groups
  }
}
