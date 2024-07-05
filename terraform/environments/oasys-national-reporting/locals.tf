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
      enable_business_unit_kms_cmks = true
      enable_image_builder          = true
      enable_ec2_cloud_watch_agent  = true
      enable_ec2_self_provision     = true
      enable_ec2_user_keypair       = true
      enable_s3_bucket              = true
      enable_s3_shared_bucket       = true
      iam_policies_filter           = ["ImageBuilderS3BucketWriteAndDeleteAccessPolicy"]
      iam_policies_ec2_default      = ["EC2S3BucketWriteAndDeleteAccessPolicy", "ImageBuilderS3BucketWriteAndDeleteAccessPolicy"]
      s3_iam_policies               = ["EC2S3BucketWriteAndDeleteAccessPolicy"]
    }
  }

  baseline_all_environments = {
    cloudwatch_log_groups = local.ssm_doc_cloudwatch_log_groups
    iam_policies = {
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
    security_groups = local.security_groups
  }
}
