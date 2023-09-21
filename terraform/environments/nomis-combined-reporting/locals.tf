locals {
  business_unit = var.networking[0].business-unit
  region        = "eu-west-2"
  environment_configs = {
    development   = local.development_config
    test          = local.test_config
    preproduction = local.preproduction_config
    production    = local.production_config
  }
  baseline_preset_options = {
    enable_application_environment_wildcard_cert = false
    enable_business_unit_kms_cmks                = true
    enable_image_builder                         = true
    enable_ec2_cloud_watch_agent                 = true
    enable_ec2_self_provision                    = true
    enable_ec2_oracle_enterprise_managed_server  = true
    enable_ec2_user_keypair                      = true
    iam_policies_filter                          = ["ImageBuilderS3BucketWriteAndDeleteAccessPolicy"]
    iam_policies_ec2_default                     = ["EC2S3BucketWriteAndDeleteAccessPolicy", "ImageBuilderS3BucketWriteAndDeleteAccessPolicy"]
    s3_iam_policies                              = ["EC2S3BucketWriteAndDeleteAccessPolicy"]

    # comment this in if you need to resolve FixNGo hostnames
    # route53_resolver_rules = {
    #   outbound-data-and-private-subnets = ["azure-fixngo-domain"]
    # }
  }
  baseline_acm_certificates         = {}
  baseline_cloudwatch_log_groups    = {}
  baseline_ec2_autoscaling_groups   = {}
  baseline_ec2_instances            = {}
  baseline_iam_policies             = {}
  baseline_iam_roles                = {}
  baseline_iam_service_linked_roles = {}
  baseline_key_pairs                = {}
  baseline_kms_grants               = {}
  baseline_lbs                      = {}
  baseline_rds_instances            = {}
  baseline_route53_resolvers        = {}
  baseline_route53_zones            = {}
  baseline_ssm_parameters           = {}
  baseline_s3_buckets = {
    s3-bucket = {
      iam_policies = module.baseline_presets.s3_iam_policies
    }
    ncr-db-backup-bucket = {
      custom_kms_key = module.environment.kms_keys["general"].arn
      iam_policies   = module.baseline_presets.s3_iam_policies
    }
  }
  environment_config = local.environment_configs[local.environment]
}
