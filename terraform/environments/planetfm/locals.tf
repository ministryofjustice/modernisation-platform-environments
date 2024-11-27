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
      cloudwatch_dashboard_default_widget_groups = [
        "network_lb",
        "ec2",
        "ec2_windows",
        "ssm_command",
      ]
      cloudwatch_metric_alarms_default_actions   = ["pagerduty"]
      cloudwatch_metric_oam_links_ssm_parameters = ["hmpps-oem-${local.environment}"]
      cloudwatch_metric_oam_links                = ["hmpps-oem-${local.environment}"]
      enable_backup_plan_daily_and_weekly        = true
      enable_business_unit_kms_cmks              = true
      enable_ec2_cloud_watch_agent               = true
      enable_ec2_self_provision                  = true
      enable_ec2_session_manager_cloudwatch_logs = true
      enable_ec2_ssm_agent_update                = true
      enable_ec2_user_keypair                    = true
      enable_hmpps_domain                        = true
      enable_image_builder                       = true
      enable_s3_bucket                           = true
      enable_s3_software_bucket                  = true
      enable_ssm_command_monitoring              = true
      s3_iam_policies                            = ["EC2S3BucketWriteAndDeleteAccessPolicy"]
    }
  }

  baseline_all_environments = {
    options = {
      enable_resource_explorer = true
    }

    cloudwatch_log_groups = local.ssm_doc_cloudwatch_log_groups
    security_groups       = local.security_groups
  }
}
