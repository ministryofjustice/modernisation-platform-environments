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
    enable_ec2_oracle_enterprise_managed_server  = true
    enable_ec2_user_keypair                      = true
    cloudwatch_metric_alarms_default_actions     = ["csr_pagerduty"]
    route53_resolver_rules = {
      # outbound-data-and-private-subnets = ["azure-fixngo-domain"]  # already set by nomis account
    }
    iam_policies_filter      = ["ImageBuilderS3BucketWriteAndDeleteAccessPolicy"]
    iam_policies_ec2_default = ["EC2S3BucketWriteAndDeleteAccessPolicy", "ImageBuilderS3BucketWriteAndDeleteAccessPolicy"]
    s3_iam_policies          = ["EC2S3BucketWriteAndDeleteAccessPolicy"]
    sns_topics = {
      pagerduty_integrations = {
        csr_pagerduty = "csr_alarms"
      }
    }
  }

  baseline_acm_certificates       = {}
  baseline_cloudwatch_log_groups  = {}
  baseline_ec2_autoscaling_groups = {}
  baseline_ec2_instances          = {}
  baseline_iam_policies = {
    CSRWebServerPolicy = {
      description = "Policy allowing access to instances via the Serial Console"
      statements = [{
        effect = "Allow"
        actions = [
          "ec2-instance-connect:SendSerialConsoleSSHPublicKey",
          "ssm:SendCommand",
          "ds:describeDirectories",
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

  baseline_secretsmanager_secrets = {}

  baseline_security_groups = {
    migration-web-sg  = local.security_groups.Web-SG-migration
    migration-app-sg  = local.security_groups.App-SG-migration
    domain-controller = local.security_groups.domain-controller-access
    domain            = local.security_groups.domain
    web               = local.security_groups.web
    app               = local.security_groups.app
    load-balancer     = local.security_groups.load-balancer
    database          = local.security_groups.database
    jumpserver        = local.security_groups.jumpserver
  }

  baseline_ssm_parameters = {}

  baseline_sns_topics = {}

}
