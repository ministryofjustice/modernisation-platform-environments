locals {
  business_unit = var.networking[0].business-unit
  region        = "eu-west-2"

  environment_baseline_presets_options = {
    development   = local.development_baseline_presets_options
    test          = local.test_baseline_presets_options
    preproduction = local.preproduction_baseline_presets_options
    production    = local.production_baseline_presets_options
  }
  environment_configs = {
    development   = local.development_config
    test          = local.test_config
    preproduction = local.preproduction_config
    production    = local.production_config
  }
  baseline_environment_presets_options = local.environment_baseline_presets_options[local.environment]
  baseline_environment_config          = local.environment_configs[local.environment]

  baseline_presets_options = {
    enable_application_environment_wildcard_cert = false
    enable_backup_plan_daily_and_weekly          = true
    enable_business_unit_kms_cmks                = true
    enable_image_builder                         = true
    enable_ec2_cloud_watch_agent                 = true
    enable_ec2_self_provision                    = true
    enable_ec2_reduced_ssm_policy                = true
    enable_ec2_user_keypair                      = true
    enable_ec2_oracle_enterprise_managed_server  = true # the oem manager manages itself, so it needs all of these permissions too
    enable_shared_s3                             = true # adds permissions to ec2s to interact with devtest or prodpreprod buckets
    db_backup_s3                                 = true # adds db backup buckets
    cloudwatch_metric_alarms_default_actions     = null # don't alarm by default as we use this account to aggregate alarms
    route53_resolver_rules = {
      # outbound-data-and-private-subnets = ["azure-fixngo-domain"]  # already set by nomis account
    }
    iam_policies_filter      = ["ImageBuilderS3BucketWriteAndDeleteAccessPolicy"]
    iam_policies_ec2_default = ["EC2S3BucketWriteAndDeleteAccessPolicy", "ImageBuilderS3BucketWriteAndDeleteAccessPolicy"]
    s3_iam_policies          = ["EC2S3BucketWriteAndDeleteAccessPolicy"]

    # sns_topics are defined in locals_${environment}.tf
  }

  baseline_acm_certificates              = {}
  baseline_backup_plans                  = {}
  baseline_cloudwatch_log_groups         = {}
  baseline_cloudwatch_log_metric_filters = {}
  baseline_cloudwatch_metric_alarms      = {}
  baseline_ec2_autoscaling_groups        = {}
  baseline_ec2_instances                 = {}
  baseline_iam_policies = {
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
  baseline_iam_roles                = {}
  baseline_iam_service_linked_roles = {}
  baseline_key_pairs                = {}
  baseline_kms_grants               = {}
  baseline_lbs                      = {}
  baseline_route53_resolvers        = {}
  baseline_route53_zones            = {}

  baseline_s3_buckets = {
    s3-bucket = {
      iam_policies = module.baseline_presets.s3_iam_policies
    }
  }

  baseline_secretsmanager_secrets = {}

  baseline_ssm_parameters = {
    "/ansible" = {
      parameters = {
        ssm_bucket = {
          description = "Ansible S3 bucket"
          value       = module.baseline.s3_buckets["s3-bucket"].bucket.bucket
        }
      }
    }
  }

  baseline_security_groups = {
    data-oem = local.security_groups.data_oem
  }

  baseline_sns_topics = {}

  environment_cloudwatch_monitoring_options = {
    development   = local.development_cloudwatch_monitoring_options
    test          = local.test_cloudwatch_monitoring_options
    preproduction = local.preproduction_cloudwatch_monitoring_options
    production    = local.production_cloudwatch_monitoring_options
  }

  cloudwatch_local_environment_monitoring_options = local.environment_cloudwatch_monitoring_options[local.environment]

  cloudwatch_monitoring_options = {
    enable_cloudwatch_monitoring_account    = false
    enable_cloudwatch_cross_account_sharing = false
    enable_cloudwatch_dashboard             = false
    monitoring_account_id                   = {}
    source_account_ids                      = {}
  }
}
