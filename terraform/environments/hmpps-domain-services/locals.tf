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
    enable_hmpps_domain                          = true
    enable_image_builder                         = true
    enable_ec2_cloud_watch_agent                 = true
    enable_ec2_self_provision                    = true
    enable_ec2_user_keypair                      = true
    enable_shared_s3                             = false # adds permissions to ec2s to interact with devtest or prodpreprod buckets
    db_backup_s3                                 = false # adds db backup buckets
    enable_oracle_secure_web                     = false # allows db to list all buckets
    cloudwatch_metric_alarms_default_actions     = ["hmpps_domain_services_pagerduty"]
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
  baseline_fsx_windows                   = {}
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
    },
    PatchBucketAccessPolicy = {
      description = "Permissions to upload and download patches"
      statements = [{
        effect = "Allow"
        actions = [
          "s3:ListBucket",
        ]
        resources = ["arn:aws:s3:::hmpps-domain-services-development-*"]
        },
        {
          effect = "Allow"
          actions = [
            "s3:PutObject",
            "s3:GetObject",
            "s3:DeleteObject",
            "s3:PutObjectAcl"
          ]
          resources = ["arn:aws:s3:::hmpps-domain-services-development-*/*"]
        }
    ] }
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
  baseline_security_groups        = local.security_groups
  baseline_ssm_documents          = {}
  baseline_ssm_parameters         = {}
  baseline_sns_topics             = {}
}
