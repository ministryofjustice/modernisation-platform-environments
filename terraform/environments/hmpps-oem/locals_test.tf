locals {

  baseline_presets_test = {
    options = {
      cloudwatch_dashboard_default_widget_groups = [
        "ec2_instance_endpoint_monitoring",
        "lb",
        "ec2",
        "ec2_linux",
        "ec2_autoscaling_group_linux",
        "ec2_instance_linux",
        "ec2_instance_oracle_db_with_backup",
        "ec2_instance_textfile_monitoring",
        "ec2_windows",
        "ssm_command",
        "github_workflows",
      ]

      enable_ec2_delius_dba_secrets_access = true

      sns_topics = {
        pagerduty_integrations = {
          azure-fixngo-pagerduty          = "az-noms-dev-test-environments-alerts"
          dso-pipelines-pagerduty         = "dso-pipelines"
          hmpps-domain-services-pagerduty = "hmpps-domain-services-test"
          nomis-pagerduty                 = "nomis-test"
          nomis-data-hub-pagerduty        = "nomis-data-hub-test"
          oasys-pagerduty                 = "oasys-test"
          pagerduty                       = "hmpps-oem-test"
        }
      }
    }
  }

  # please keep resources in alphabetical order
  baseline_test = {

    cloudwatch_metric_alarms = merge(
      local.cloudwatch_metric_alarms_github_actions, # gha metrics are only pushed to hmpps-oem-test account
    )

    cloudwatch_dashboards = {
      "endpoints-and-pipelines" = {
        account_name   = "hmpps-oem-test"
        periodOverride = "auto"
        start          = "-PT6H"
        widget_groups = [
          module.baseline_presets.cloudwatch_dashboard_widget_groups.ec2_instance_endpoint_monitoring,
          module.baseline_presets.cloudwatch_dashboard_widget_groups.ssm_command,
          module.baseline_presets.cloudwatch_dashboard_widget_groups.github_workflows,
        ]
      }
      "hmpps-domain-services-test" = {
        account_name   = "hmpps-domain-services-test"
        periodOverride = "auto"
        start          = "-PT6H"
        widget_groups = [
          merge(module.baseline_presets.cloudwatch_dashboard_widget_groups.ec2_instance_endpoint_monitoring, {
            account_name = "hmpps-oem-test"
            search_filter_dimension = {
              name = "type_instance"
              values = [
                "rdgateway1.test.hmpps-domain.service.justice.gov.uk",
              ]
            }
          }),
          module.baseline_presets.cloudwatch_dashboard_widget_groups.lb,
          module.baseline_presets.cloudwatch_dashboard_widget_groups.ec2,
          module.baseline_presets.cloudwatch_dashboard_widget_groups.ec2_windows,
        ]
      }
      "hmpps-oem-test" = {
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
      "nomis-test" = {
        account_name   = "nomis-test"
        periodOverride = "auto"
        start          = "-PT6H"
        widget_groups = [
          merge(module.baseline_presets.cloudwatch_dashboard_widget_groups.ec2_instance_endpoint_monitoring, {
            account_name = "hmpps-oem-test"
            search_filter_dimension = {
              name = "type_instance"
              values = [
                "c-t1.test.nomis.service.justice.gov.uk",
                "c-t2.test.nomis.service.justice.gov.uk",
                "c-t3.test.nomis.service.justice.gov.uk",
              ]
            }
          }),
          module.baseline_presets.cloudwatch_dashboard_widget_groups.lb,
          module.baseline_presets.cloudwatch_dashboard_widget_groups.ec2,
          module.baseline_presets.cloudwatch_dashboard_widget_groups.ec2_linux,
          module.baseline_presets.cloudwatch_dashboard_widget_groups.ec2_autoscaling_group_linux,
          module.baseline_presets.cloudwatch_dashboard_widget_groups.ec2_instance_linux,
          module.baseline_presets.cloudwatch_dashboard_widget_groups.ec2_instance_oracle_db_with_backup,
          module.baseline_presets.cloudwatch_dashboard_widget_groups.ec2_instance_textfile_monitoring,
          module.baseline_presets.cloudwatch_dashboard_widget_groups.ec2_windows,
          module.baseline_presets.cloudwatch_dashboard_widget_groups.ssm_command,
        ]
      }
      "nomis-combined-reporting-test" = {
        account_name   = "nomis-combined-reporting-test"
        periodOverride = "auto"
        start          = "-PT6H"
        widget_groups = [
          module.baseline_presets.cloudwatch_dashboard_widget_groups.lb,
          module.baseline_presets.cloudwatch_dashboard_widget_groups.ec2,
          module.baseline_presets.cloudwatch_dashboard_widget_groups.ec2_linux,
          module.baseline_presets.cloudwatch_dashboard_widget_groups.ec2_instance_linux,
          module.baseline_presets.cloudwatch_dashboard_widget_groups.ec2_instance_oracle_db_with_backup,
          module.baseline_presets.cloudwatch_dashboard_widget_groups.ec2_instance_filesystems,
          module.baseline_presets.cloudwatch_dashboard_widget_groups.ec2_windows,
        ]
      }
      "nomis-data-hub-test" = {
        account_name   = "nomis-data-hub-test"
        periodOverride = "auto"
        start          = "-PT6H"
        widget_groups = [
          module.baseline_presets.cloudwatch_dashboard_widget_groups.ec2,
          module.baseline_presets.cloudwatch_dashboard_widget_groups.ec2_linux,
          module.baseline_presets.cloudwatch_dashboard_widget_groups.ec2_instance_linux,
          module.baseline_presets.cloudwatch_dashboard_widget_groups.ec2_instance_textfile_monitoring,
          module.baseline_presets.cloudwatch_dashboard_widget_groups.ec2_windows,
        ]
      }
      "oasys-test" = {
        account_name   = "oasys-test"
        periodOverride = "auto"
        start          = "-PT6H"
        widget_groups = [
          merge(module.baseline_presets.cloudwatch_dashboard_widget_groups.ec2_instance_endpoint_monitoring, {
            account_name = "hmpps-oem-test"
            search_filter_dimension = {
              name = "type_instance"
              values = [
                "t1-int.oasys.service.justice.gov.uk",
                "t2-int.oasys.service.justice.gov.uk",
              ]
            }
          }),
          module.baseline_presets.cloudwatch_dashboard_widget_groups.lb,
          module.baseline_presets.cloudwatch_dashboard_widget_groups.ec2,
          module.baseline_presets.cloudwatch_dashboard_widget_groups.ec2_linux,
          module.baseline_presets.cloudwatch_dashboard_widget_groups.ec2_autoscaling_group_linux,
          module.baseline_presets.cloudwatch_dashboard_widget_groups.ec2_instance_linux,
          module.baseline_presets.cloudwatch_dashboard_widget_groups.ec2_instance_oracle_db_with_backup,
        ]
      }
      "oasys-national-reporting-test" = {
        account_name   = "oasys-national-reporting-test"
        periodOverride = "auto"
        start          = "-PT6H"
        widget_groups = [
          module.baseline_presets.cloudwatch_dashboard_widget_groups.ec2,
          module.baseline_presets.cloudwatch_dashboard_widget_groups.ec2_linux,
          module.baseline_presets.cloudwatch_dashboard_widget_groups.ec2_instance_linux,
          module.baseline_presets.cloudwatch_dashboard_widget_groups.ec2_windows,
        ]
      }
    }

    ec2_autoscaling_groups = {
      test-oem = merge(local.ec2_instances.oem, {
        autoscaling_group = {
          desired_capacity    = 0
          max_size            = 1
          force_delete        = true
          vpc_zone_identifier = module.environment.subnets["private"].ids
        }
        cloudwatch_metric_alarms = {}
        tags = merge(local.ec2_instances.oem.tags, {
          oracle-sids = "EMREP TRCVCAT"
        })
      })
    }

    ec2_instances = {
      test-oem-a = merge(local.ec2_instances.oem, {
        cloudwatch_metric_alarms = merge(
          local.ec2_instances.oem.cloudwatch_metric_alarms,
          local.cloudwatch_metric_alarms_endpoint_monitoring
        )
        config = merge(local.ec2_instances.oem.config, {
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
          oracle-sids = "EMREP TRCVCAT"
        })
      })
    }

    oam_sinks = {
      "CloudWatchMetricOamSink" = {
        resource_types = ["AWS::CloudWatch::Metric"]
        source_account_names = [
          "hmpps-domain-services-test",
          "nomis-test",
          "nomis-combined-reporting-test",
          "nomis-data-hub-test",
          "oasys-test",
          "oasys-national-reporting-test",
        ]
      }
    }

    route53_zones = {
      "hmpps-test.modernisation-platform.service.justice.gov.uk" = {
        records = [
          { name = "oem.hmpps-oem", type = "CNAME", ttl = "300", records = ["test-oem-a.hmpps-oem.hmpps-test.modernisation-platform.service.justice.gov.uk"] },
        ]
      }
    }

    secretsmanager_secrets = {
      "/oracle/oem"              = local.secretsmanager_secrets.oem
      "/oracle/database/EMREP"   = local.secretsmanager_secrets.oem
      "/oracle/database/TRCVCAT" = local.secretsmanager_secrets.oem
    }
  }
}
