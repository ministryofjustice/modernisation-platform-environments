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
      ]
      enable_backup_plan_daily_and_weekly         = true
      enable_business_unit_kms_cmks               = true
      enable_image_builder                        = true
      enable_ec2_cloud_watch_agent                = true
      enable_ec2_reduced_ssm_policy               = true
      enable_ec2_self_provision                   = true
      enable_ec2_oracle_enterprise_managed_server = true
      enable_ec2_user_keypair                     = true
      enable_s3_db_backup_bucket                  = true
      enable_s3_shared_bucket                     = true
      iam_policies_filter                         = ["ImageBuilderS3BucketWriteAndDeleteAccessPolicy"]
      iam_policies_ec2_default                    = ["EC2S3BucketWriteAndDeleteAccessPolicy", "ImageBuilderS3BucketWriteAndDeleteAccessPolicy"]
      s3_iam_policies                             = ["EC2S3BucketWriteAndDeleteAccessPolicy"]
    }
  }

  baseline_all_environments = {
    cloudwatch_dashboards = {
      "hmpps-oem-${local.environment}" = {
        account_name   = "hmpps-oem-${local.environment}"
        periodOverride = "auto"
        start          = "-PT6H"
        widget_groups = [
          module.baseline_presets.cloudwatch_dashboard_widget_groups.ec2,
          module.baseline_presets.cloudwatch_dashboard_widget_groups.ec2_linux,
          module.baseline_presets.cloudwatch_dashboard_widget_groups.ec2_instance_linux,
          module.baseline_presets.cloudwatch_dashboard_widget_groups.ec2_instance_oracle_db_with_backup,
          module.baseline_presets.cloudwatch_dashboard_widget_groups.ec2_instance_textfile_monitoring,
        ]
      }
      "nomis-${local.environment}" = {
        account_name   = "nomis-${local.environment}"
        periodOverride = "auto"
        start          = "-PT6H"
        widget_groups = [
          module.baseline_presets.cloudwatch_dashboard_widget_groups.lb,
          module.baseline_presets.cloudwatch_dashboard_widget_groups.ec2,
          module.baseline_presets.cloudwatch_dashboard_widget_groups.ec2_linux,
          module.baseline_presets.cloudwatch_dashboard_widget_groups.ec2_autoscaling_group_linux,
          module.baseline_presets.cloudwatch_dashboard_widget_groups.ec2_instance_linux,
          module.baseline_presets.cloudwatch_dashboard_widget_groups.ec2_instance_oracle_db_with_backup,
          module.baseline_presets.cloudwatch_dashboard_widget_groups.ec2_instance_textfile_monitoring,
        ]
      }
      "corporate-staff-rostering-${local.environment}" = {
        account_name   = "corporate-staff-rostering-${local.environment}"
        periodOverride = "auto"
        start          = "-PT6H"
        widget_groups = [
          module.baseline_presets.cloudwatch_dashboard_widget_groups.ec2,
          module.baseline_presets.cloudwatch_dashboard_widget_groups.ec2_linux,
          module.baseline_presets.cloudwatch_dashboard_widget_groups.ec2_instance_linux,
          module.baseline_presets.cloudwatch_dashboard_widget_groups.ec2_instance_oracle_db_with_backup,
        ]
      }
    }
    iam_policies = {
      Ec2OracleEnterpriseManagerPolicy = {
        description = "Permissions required for Oracle Enterprise Manager"
        statements = [
          {
            sid    = "S3ListLocation"
            effect = "Allow"
            actions = [
              "s3:ListAllMyBuckets",
              "s3:GetBucketLocation",
            ]
            resources = [
              "arn:aws:s3:::*"
            ]
          },
          {
            sid    = "SecretsmanagerReadWriteOracleOem"
            effect = "Allow"
            actions = [
              "secretsmanager:GetSecretValue",
              "secretsmanager:PutSecretValue",
            ]
            resources = [
              "arn:aws:secretsmanager:*:*:secret:/oracle/*",
            ]
          },
          {
            sid    = "SSMReadAccountIdsOracle"
            effect = "Allow"
            actions = [
              "ssm:GetParameter",
              "ssm:GetParameters",
            ]
            resources = [
              "arn:aws:ssm:*:*:parameter/account_ids",
              "arn:aws:ssm:*:*:parameter/oracle/*",
            ]
          },
          {
            sid    = "SSMWriteOracle"
            effect = "Allow"
            actions = [
              "ssm:PutParameter",
              "ssm:PutParameters",
            ]
            resources = [
              "arn:aws:ssm:*:*:parameter/oracle/*",
            ]
          }
        ]
      }
    }

    oam_sinks = {
      "CloudWatchMetricOamSink" = {
        resource_types = ["AWS::CloudWatch::Metric"]
        source_account_names = [
          "corporate-staff-rostering-${local.environment}",
          "hmpps-domain-services-${local.environment}",
          "nomis-${local.environment}",
          "nomis-combined-reporting-${local.environment}",
          "nomis-data-hub-${local.environment}",
          "oasys-${local.environment}",
          "oasys-national-reporting-${local.environment}",
          "planetfm-${local.environment}",
        ]
      }
    }

    s3_buckets = {
      s3-bucket = {
        iam_policies = module.baseline_presets.s3_iam_policies
      }
    }

    security_groups = {
      data-oem = local.security_groups.data_oem
    }

    ssm_parameters = {
      "/ansible" = {
        parameters = {
          ssm_bucket = {
            description          = "Ansible S3 bucket"
            value_s3_bucket_name = "s3-bucket"
          }
        }
      }
    }
  }
}
