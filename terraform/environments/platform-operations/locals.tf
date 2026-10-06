#### This file can be used to store locals specific to the member account ####
locals {
  account_config = local.application_data.accounts[local.environment]

  baseline_presets_all_environments = {
    options = {
      cloudwatch_metric_alarms_default_actions    = ["dso-pipelines-pagerduty"]
      enable_business_unit_kms_cmks               = true
      enable_ec2_cloud_watch_agent                = true
      enable_ec2_oracle_enterprise_managed_server = true
      enable_ec2_security_groups                  = true
      enable_ec2_self_provision                   = true
      enable_ec2_ssm_agent_update                 = true
      enable_ec2_user_keypair                     = true
      enable_image_builder                        = true
      enable_s3_bucket                            = true
      enable_ssm_command_monitoring               = true
      s3_iam_policies                             = ["EC2S3BucketWriteAndDeleteAccessPolicy"]
    }
  }
  baseline_presets_environments_specific = {
    development = local.baseline_presets_development
    production  = local.baseline_presets_production
  }
  baseline_presets_environment_specific = local.baseline_presets_environments_specific[local.environment]

  baseline_all_environments = {
    options = {
      enable_resource_explorer = true
    }
  }

  baseline_environments_specific = {
    development = local.baseline_development
    production  = local.baseline_production
  }
  baseline_environment_specific = local.baseline_environments_specific[local.environment]

  github_actions_lambda_environments_specific = {
    development = local.github_actions_lambda_development
    production  = local.github_actions_lambda_production
  }
  github_actions_lambda_environment_specific = local.github_actions_lambda_environments_specific[local.environment]
}