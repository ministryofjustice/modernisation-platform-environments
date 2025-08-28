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
      cloudwatch_metric_alarms_default_actions    = ["pagerduty"]
      enable_backup_plan_daily_and_weekly         = true
      enable_business_unit_kms_cmks               = true
      enable_ec2_cloud_watch_agent                = true
      enable_ec2_oracle_enterprise_managed_server = true
      enable_ec2_self_provision                   = true
      enable_ec2_session_manager_cloudwatch_logs  = true
      enable_ec2_ssm_agent_update                 = true
      enable_ec2_user_keypair                     = true
      enable_image_builder                        = true
      enable_s3_bucket                            = true
      enable_s3_db_backup_bucket                  = true
      enable_s3_shared_bucket                     = true
      enable_s3_software_bucket                   = true
      enable_ssm_command_monitoring               = true
      enable_ssm_missing_metric_monitoring        = true
      s3_iam_policies                             = ["EC2S3BucketWriteAndDeleteAccessPolicy"]
    }
  }

  baseline_all_environments = {
    options = {
      enable_resource_explorer = true
    }

    iam_policies = {
      Ec2OracleEnterpriseManagerPolicy = {
        description = "Permissions required for Oracle Enterprise Manager"
        statements = [
          {
            sid    = "S3ListLocation"
            effect = "Allow"
            actions = [
              "s3:ListAllMyBuckets",
              "s3:GetBucketLocation",
            ]
            resources = [
              "arn:aws:s3:::*"
            ]
          },
          {
            sid    = "SecretsmanagerReadWriteOracleOem"
            effect = "Allow"
            actions = [
              "secretsmanager:GetSecretValue",
              "secretsmanager:PutSecretValue",
            ]
            resources = [
              "arn:aws:secretsmanager:*:*:secret:/oracle/*",
            ]
          },
          {
            sid    = "SSMReadAccountIdsOracle"
            effect = "Allow"
            actions = [
              "ssm:GetParameter",
              "ssm:GetParameters",
            ]
            resources = [
              "arn:aws:ssm:*:*:parameter/account_ids",
              "arn:aws:ssm:*:*:parameter/oracle/*",
            ]
          },
          {
            sid    = "SSMWriteOracle"
            effect = "Allow"
            actions = [
              "ssm:PutParameter",
              "ssm:PutParameters",
            ]
            resources = [
              "arn:aws:ssm:*:*:parameter/oracle/*",
            ]
          }
        ]
      }
    }

    security_groups = local.security_groups
  }
}
