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
        "lb_expression",
        "ec2_linux_only_expression",
        "ec2_service_status_expression",
        "ec2_textfile_monitoring_expression",
        "ec2_oracle_db_with_backup_expression",
      ]
      cloudwatch_metric_alarms_default_actions    = ["dso_pagerduty"]
      cloudwatch_metric_oam_links_ssm_parameters  = ["hmpps-oem-${local.environment}"]
      enable_azure_sas_token                      = true
      enable_backup_plan_daily_and_weekly         = true
      enable_business_unit_kms_cmks               = true
      enable_image_builder                        = true
      enable_ec2_cloud_watch_agent                = true
      enable_ec2_reduced_ssm_policy               = true
      enable_ec2_self_provision                   = true
      enable_ec2_oracle_enterprise_managed_server = true
      enable_ec2_user_keypair                     = true
      iam_policies_filter                         = ["ImageBuilderS3BucketWriteAndDeleteAccessPolicy"]
      iam_policies_ec2_default                    = ["EC2S3BucketWriteAndDeleteAccessPolicy", "ImageBuilderS3BucketWriteAndDeleteAccessPolicy"]
      route53_resolver_rules = {
        outbound-data-and-private-subnets = ["azure-fixngo-domain"]
      }
      s3_iam_policies = ["EC2S3BucketWriteAndDeleteAccessPolicy"]
    }
  }

  baseline_all_environments = {
    cloudwatch_log_groups = merge(
      local.weblogic_cloudwatch_log_groups,
      local.database_cloudwatch_log_groups,
    )

    s3_buckets = {
      s3-bucket = {
        iam_policies = module.baseline_presets.s3_iam_policies
      }
    }

    security_groups = {
      private-lb         = local.security_groups.private_lb
      private-web        = local.security_groups.private_web
      private-jumpserver = local.security_groups.private_jumpserver
      data-db            = local.security_groups.data_db
    }
  }
}
