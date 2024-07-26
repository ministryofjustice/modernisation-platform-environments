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
        "lb",
        "ec2",
        "ec2_linux",
        "ec2_autoscaling_group_linux",
        "ec2_instance_linux",
        "ec2_instance_oracle_db_with_backup",
        "ec2_instance_textfile_monitoring",
        "ec2_windows",
      ]
      cloudwatch_metric_alarms_default_actions    = ["dso_pagerduty"]
      cloudwatch_metric_oam_links_ssm_parameters  = ["hmpps-oem-${local.environment}"]
      cloudwatch_metric_oam_links                 = ["hmpps-oem-${local.environment}"]
      db_backup_bucket_name                       = "nomis-db-backup-bucket"
      enable_backup_plan_daily_and_weekly         = true
      enable_business_unit_kms_cmks               = true
      enable_ec2_cloud_watch_agent                = true
      enable_ec2_oracle_enterprise_managed_server = true
      enable_ec2_self_provision                   = true
      enable_ec2_session_manager_cloudwatch_logs  = true
      enable_ec2_ssm_agent_update                 = true
      enable_ec2_user_keypair                     = true
      enable_hmpps_domain                         = true # Syscon users are collaborators so need domain creds to access nomis-client EC2s
      enable_image_builder                        = true
      enable_s3_bucket                            = true
      enable_s3_db_backup_bucket                  = true
      enable_s3_software_bucket                   = true
      route53_resolver_rules                      = { outbound-data-and-private-subnets = ["azure-fixngo-domain"] }
      s3_iam_policies                             = ["EC2S3BucketWriteAndDeleteAccessPolicy"]
      software_bucket_name                        = "ec2-image-builder-nomis"
    }
  }

  baseline_all_environments = {
    options = {
      enable_resource_explorer = true
    }

    security_groups = local.security_groups
  }
}
