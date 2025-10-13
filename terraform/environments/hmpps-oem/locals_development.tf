locals {

  baseline_presets_development = {
    options = {
      cloudwatch_dashboard_default_widget_groups = [
        "lb",
        "ec2",
        "ec2_linux",
        "ec2_autoscaling_group_linux",
        "ec2_instance_linux",
        "ec2_instance_oracle_db_with_backup",
        "ec2_windows",
        "ssm_command",
      ]

      enable_ec2_delius_dba_secrets_access = true

      sns_topics = {
        pagerduty_integrations = {
          dso-pipelines-pagerduty = "dso-pipelines"
          pagerduty               = "hmpps-oem-development"
        }
      }
    }
  }

  # please keep resources in alphabetical order
  baseline_development = {

    "endpoints-and-pipelines" = {
      account_name   = "hmpps-oem-development"
      periodOverride = "auto"
      start          = "-PT6H"
      widget_groups = [
        module.baseline_presets.cloudwatch_dashboard_widget_groups.ssm_command,
      ]
    }
    "hmpps-oem-development" = {
      account_name   = null
      periodOverride = "auto"
      start          = "-PT6H"
      widget_groups = [{
        header_markdown = "## EC2 Oracle Enterprise Management"
        width           = 8
        height          = 8
        add_ebs_widgets = {
          iops       = true
          throughput = true
        }
        search_filter = {
          ec2_tag = [
            { tag_name = "server-type", tag_value = "hmpps-oem" },
          ]
        }
        widgets = [
          module.baseline_presets.cloudwatch_dashboard_widgets.ec2.cpu-utilization-high,
          module.baseline_presets.cloudwatch_dashboard_widgets.ec2.instance-status-check-failed,
          module.baseline_presets.cloudwatch_dashboard_widgets.ec2.system-status-check-failed,
          module.baseline_presets.cloudwatch_dashboard_widgets.ec2_cwagent_linux.free-disk-space-low,
          module.baseline_presets.cloudwatch_dashboard_widgets.ec2_cwagent_linux.high-memory-usage,
          module.baseline_presets.cloudwatch_dashboard_widgets.ec2_cwagent_linux.cpu-iowait-high,
          module.baseline_presets.cloudwatch_dashboard_widgets.ec2_instance_cwagent_linux.free-disk-space-low,
          module.baseline_presets.cloudwatch_dashboard_widgets.ec2_instance_cwagent_collectd_service_status_os.service-status-error-os-layer,
          module.baseline_presets.cloudwatch_dashboard_widgets.ec2_instance_cwagent_collectd_service_status_app.service-status-error-app-layer,
          module.baseline_presets.cloudwatch_dashboard_widgets.ec2_instance_cwagent_collectd_oracle_db_connected.oracle-db-disconnected,
          module.baseline_presets.cloudwatch_dashboard_widgets.ec2_instance_cwagent_collectd_oracle_db_backup.oracle-db-rman-backup-error,
          module.baseline_presets.cloudwatch_dashboard_widgets.ec2_instance_cwagent_collectd_oracle_db_backup.oracle-db-rman-backup-did-not-run,
        ]
      }]
    }
    "nomis-development" = {
      account_name   = "nomis-development"
      periodOverride = "auto"
      start          = "-PT6H"
      widget_groups = [
        module.baseline_presets.cloudwatch_dashboard_widget_groups.lb,
        module.baseline_presets.cloudwatch_dashboard_widget_groups.ec2,
        module.baseline_presets.cloudwatch_dashboard_widget_groups.ec2_linux,
        module.baseline_presets.cloudwatch_dashboard_widget_groups.ec2_autoscaling_group_linux,
        module.baseline_presets.cloudwatch_dashboard_widget_groups.ec2_instance_linux,
        module.baseline_presets.cloudwatch_dashboard_widget_groups.ec2_instance_oracle_db_with_backup,
        module.baseline_presets.cloudwatch_dashboard_widget_groups.ec2_windows,
        module.baseline_presets.cloudwatch_dashboard_widget_groups.ssm_command,
      ]
    }

    ec2_autoscaling_groups = {
      dev-base-ol85 = {
        autoscaling_group = {
          desired_capacity    = 0
          max_size            = 1
          force_delete        = true
          vpc_zone_identifier = module.environment.subnets["private"].ids
        }
        config = {
          ami_name                  = "base_ol_8_5*"
          iam_resource_names_prefix = "ec2-instance"
          instance_profile_policies = [
            "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore",
            "EC2Default",
            "EC2S3BucketWriteAndDeleteAccessPolicy",
            "ImageBuilderS3BucketWriteAndDeleteAccessPolicy"
          ]
          subnet_name = "private"
        }
        instance = {
          disable_api_termination      = false
          instance_type                = "t3.medium"
          key_name                     = "ec2-user"
          vpc_security_group_ids       = ["data-oem"]
          metadata_options_http_tokens = "required"
          monitoring                   = false
        }
        user_data_cloud_init = {
          args = {
            branch       = "main"
            ansible_args = "--tags ec2provision"
          }
          scripts = [ # paths are relative to templates/ dir
            "../../../modules/baseline_presets/ec2-user-data/install-ssm-agent.sh",
            "../../../modules/baseline_presets/ec2-user-data/ansible-ec2provision.sh.tftpl",
            "../../../modules/baseline_presets/ec2-user-data/post-ec2provision.sh",
          ]
        }
        tags = {
          backup           = "false"
          description      = "For testing our base OL8.5 base image"
          component        = "test"
          os-type          = "Linux"
          server-type      = "base-ol85"
          update-ssm-agent = "patchgroup1"
        }
      }
    }

    ec2_instances = {
      dev-oem-a = merge(local.ec2_instances.oem, {
        cloudwatch_metric_alarms = merge(
          local.ec2_instances.oem.cloudwatch_metric_alarms,
          local.cloudwatch_metric_alarms_endpoint_monitoring
        )
        config = merge(local.ec2_instances.oem.config, {
          ami_name          = "hmpps_ol_8_5_oracledb_19c_release_2023-12-07T12-10-49.620Z"
          availability_zone = "eu-west-2a"
        })
        instance = merge(local.ec2_instances.oem.instance, {
          disable_api_termination = true
        })
        user_data_cloud_init = merge(local.ec2_instances.oem.user_data_cloud_init, {
          args = merge(local.ec2_instances.oem.user_data_cloud_init.args, {
            branch = "45027fb7482eb7fb601c9493513bb73658780dda" # 2023-08-11
          })
        })
        tags = merge(local.ec2_instances.oem.tags, {
          oracle-sids = "EMREP DEVRCVCAT"
        })
      })
    }

    oam_sinks = {
      "CloudWatchMetricOamSink" = {
        resource_types = ["AWS::CloudWatch::Metric"]
        source_account_names = [
          "hmpps-domain-services-development",
          "nomis-development",
          "nomis-data-hub-development",
          "oasys-development",
        ]
      }
    }

    secretsmanager_secrets = {
      "/oracle/oem"                = local.secretsmanager_secrets.oem
      "/oracle/database/EMREP"     = local.secretsmanager_secrets.oem
      "/oracle/database/DEVRCVCAT" = local.secretsmanager_secrets.oem
    }
  }
}
