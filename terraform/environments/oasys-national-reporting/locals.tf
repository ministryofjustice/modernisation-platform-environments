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
    # cloudwatch_metric_alarms_default_actions     = ["onr_pagerduty"]
    enable_application_environment_wildcard_cert = false
    enable_backup_plan_daily_and_weekly          = true
    enable_business_unit_kms_cmks                = true
    enable_hmpps_domain                          = true
    enable_image_builder                         = true
    enable_ec2_cloud_watch_agent                 = true
    enable_ec2_self_provision                    = true
    enable_ec2_user_keypair                      = true
    enable_shared_s3                             = true

    cloudwatch_metric_alarms = {}
    route53_resolver_rules = {
      # outbound-data-and-private-subnets = ["azure-fixngo-domain"]  # already set by nomis account
    }
    iam_policies_filter      = ["ImageBuilderS3BucketWriteAndDeleteAccessPolicy"]
    iam_policies_ec2_default = ["EC2S3BucketWriteAndDeleteAccessPolicy", "ImageBuilderS3BucketWriteAndDeleteAccessPolicy"]
    s3_iam_policies          = ["EC2S3BucketWriteAndDeleteAccessPolicy"]
    # sns_topics = {
    #   pagerduty_integrations = {
    #     onr_pagerduty = "onr_alarms"
    #   }
    # }
  }

  baseline_acm_certificates = {}
  baseline_cloudwatch_log_groups = merge(
    local.ssm_doc_cloudwatch_log_groups, {}
  )

  baseline_ec2_autoscaling_groups = {}
  baseline_ec2_instances          = {}
  baseline_iam_policies = {
    SSMPolicy = {
      description = "Policy to allow ssm actions"
      statements = [{
        effect = "Allow"
        actions = [
          "ssm:SendCommand"
        ]
        resources = ["*"]
      }]
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

  baseline_security_groups = {
    # instance type security groups
    # loadbalancer              = local.security_groups.loadbalancer
    web    = local.security_groups.web # apply to onr web servers
    bods   = local.security_groups.bods
    boe    = local.security_groups.boe
    onr_db = local.security_groups.onr_db

    # shared security groups
    oasys_db        = local.security_groups.oasys_db        # apply to bods & boe servers
    oasys_db_onr_db = local.security_groups.oasys_db_onr_db # apply to onr_db prod server
  }

  baseline_sns_topics     = {}
  baseline_ssm_parameters = {}
  baseline_secretsmanager_secrets = {}
}
