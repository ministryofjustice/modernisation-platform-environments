locals {
  business_unit = var.networking[0].business-unit
  region        = "eu-west-2"

  environment_configs = {
    development   = local.development_config
    test          = local.test_config
    preproduction = local.preproduction_config
    production    = local.production_config
  }
  baseline_environment_config = local.environment_configs[local.environment]

  baseline_presets_options = {
    enable_application_environment_wildcard_cert = false
    enable_backup_plan_daily_and_weekly          = true
    enable_business_unit_kms_cmks                = true
    enable_image_builder                         = true
    enable_ec2_cloud_watch_agent                 = true
    enable_ec2_self_provision                    = true
    enable_oracle_secure_web                     = true
    enable_ec2_put_parameter                     = true
    enable_ec2_put_secret                        = true
    enable_shared_s3                             = true # adds permissions to ec2s to interact with devtest or prodpreprod buckets
    db_backup_s3                                 = true # adds db backup buckets
    enable_oracle_secure_web                     = true # allows db to list all buckets
    cloudwatch_metric_alarms                     = {}
    route53_resolver_rules = {
      # outbound-data-and-private-subnets = ["azure-fixngo-domain"]  # already set by nomis account
    }
    iam_policies_filter      = ["ImageBuilderS3BucketWriteAndDeleteAccessPolicy"]
    iam_policies_ec2_default = ["EC2S3BucketWriteAndDeleteAccessPolicy", "ImageBuilderS3BucketWriteAndDeleteAccessPolicy"]
    s3_iam_policies          = ["EC2S3BucketWriteAndDeleteAccessPolicy"]
    sns_topics               = {}
  }

  baseline_acm_certificates              = {}
  baseline_backup_plans                  = {}
  baseline_cloudwatch_log_groups         = {}
  baseline_cloudwatch_log_metric_filters = {}
  baseline_cloudwatch_metric_alarms      = {}
  baseline_ec2_autoscaling_groups        = {}
  baseline_ec2_instances                 = {}
  baseline_iam_policies                  = {}
  baseline_iam_roles                     = {}
  baseline_iam_service_linked_roles      = {}
  baseline_key_pairs                     = {}
  baseline_kms_grants                    = {}
  baseline_lbs                           = {}
  baseline_route53_resolvers             = {}
  baseline_route53_zones                 = {}

  baseline_s3_buckets = {
    s3-bucket = {
      iam_policies = module.baseline_presets.s3_iam_policies
    }
  }

  baseline_secretsmanager_secrets = {
    "/ec2/oracle/oem" = local.oem_secretsmanager_secrets
  }

  baseline_security_groups = {
    data-oem = local.security_groups.data_oem
  }

  baseline_sns_topics = {}

  baseline_ssm_parameters = {
    # ssm params at root level
    "" = {
      prefix  = ""
      postfix = ""
      parameters = {
        ec2-user_pem = {}
      }
    }
  }
}
