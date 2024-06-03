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
        "ec2_instance_linux",
        "ec2_instance_oracle_db_with_backup",
        "ec2_instance_textfile_monitoring",
      ]
      cloudwatch_metric_oam_links_ssm_parameters  = ["hmpps-oem-${local.environment}"]
      enable_azure_sas_token                      = true
      enable_backup_plan_daily_and_weekly         = true
      enable_business_unit_kms_cmks               = true
      enable_hmpps_domain                         = true
      enable_image_builder                        = true
      enable_ec2_cloud_watch_agent                = true
      enable_ec2_self_provision                   = true
      enable_ec2_oracle_enterprise_managed_server = true
      enable_ec2_user_keypair                     = true
      iam_policies_filter                         = ["ImageBuilderS3BucketWriteAndDeleteAccessPolicy"]
      iam_policies_ec2_default                    = ["EC2S3BucketWriteAndDeleteAccessPolicy", "ImageBuilderS3BucketWriteAndDeleteAccessPolicy"]
      s3_iam_policies                             = ["EC2S3BucketWriteAndDeleteAccessPolicy"]
      sns_topics = {
        pagerduty_integrations = {
          csr_pagerduty = "csr_alarms"
        }
      }
    }
  }

  baseline_all_environments = {
    cloudwatch_log_groups = merge(local.ssm_doc_cloudwatch_log_groups, {
      cwagent-windows-application = {
        retention_in_days = 30
      }
      cwagent-windows-application-json = {
        retention_in_days = 30
      }
    })

    cloudwatch_log_metric_filters = local.application_log_metric_filters

    iam_policies = {
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

    s3_buckets = {
      s3-bucket = {
        iam_policies = module.baseline_presets.s3_iam_policies
      }
    }

    security_groups = {
      domain        = local.security_groups.domain
      web           = local.security_groups.web
      app           = local.security_groups.app
      load-balancer = local.security_groups.load-balancer
      database      = local.security_groups.database
      jumpserver    = local.security_groups.jumpserver
    }
  }
}
