locals {

  baseline_presets_production = {
    options = {
      cloudwatch_dashboard_default_widget_groups = [
        "ec2_instance_endpoint_monitoring",
        "network_lb",
        "lb",
        "ec2",
        "ec2_linux",
        "ec2_autoscaling_group_linux",
        "ec2_instance_linux",
        "ec2_instance_oracle_db_with_backup",
        "ec2_instance_textfile_monitoring",
        "ec2_windows",
        "ssm_command",
      ]

      sns_topics = {
        pagerduty_integrations = {
          azure-fixngo-pagerduty              = "az-noms-production-1-alerts"
          corporate-staff-rostering-pagerduty = "corporate-staff-rostering-production"
          dso-pipelines-pagerduty             = "dso-pipelines"
          hmpps-domain-services-pagerduty     = "hmpps-domain-services-production"
          nomis-combined-reporting-pagerduty  = "nomis-combined-reporting-production"
          nomis-pagerduty                     = "nomis-production"
          oasys-national-reporting-pagerduty  = "oasys-national-reporting-production"
          oasys-pagerduty                     = "oasys-production"
          pagerduty                           = "hmpps-oem-production"
          planetfm-pagerduty                  = "planetfm-production"
        }
      }
    }
  }

  # please keep resources in alphabetical order
  baseline_production = {

    cloudwatch_dashboards = {
      "corporate-staff-rostering-production" = {
        account_name   = "corporate-staff-rostering-production"
        periodOverride = "auto"
        start          = "-PT6H"
        widget_groups = [
          merge(module.baseline_presets.cloudwatch_dashboard_widget_groups.ec2_instance_endpoint_monitoring, {
            account_name = "hmpps-oem-production"
            search_filter_dimension = {
              name = "type_instance"
              values = [
                "r1.csr.service.justice.gov.uk",
                "r2.csr.service.justice.gov.uk",
                "r3.csr.service.justice.gov.uk",
                "r4.csr.service.justice.gov.uk",
                "r5.csr.service.justice.gov.uk",
                "r6.csr.service.justice.gov.uk",
              ]
            }
          }),
          module.baseline_presets.cloudwatch_dashboard_widget_groups.network_lb,
          module.baseline_presets.cloudwatch_dashboard_widget_groups.ec2,
          module.baseline_presets.cloudwatch_dashboard_widget_groups.ec2_linux,
          module.baseline_presets.cloudwatch_dashboard_widget_groups.ec2_instance_linux,
          module.baseline_presets.cloudwatch_dashboard_widget_groups.ec2_instance_oracle_db_with_backup,
        ]
      }
      "endpoints-and-pipelines" = {
        account_name   = "hmpps-oem-production"
        periodOverride = "auto"
        start          = "-PT6H"
        widget_groups = [
          module.baseline_presets.cloudwatch_dashboard_widget_groups.ec2_instance_endpoint_monitoring,
          module.baseline_presets.cloudwatch_dashboard_widget_groups.ssm_command,
        ]
      }
      "hmpps-domain-services-production" = {
        account_name   = "hmpps-domain-services-production"
        periodOverride = "auto"
        start          = "-PT6H"
        widget_groups = [
          merge(module.baseline_presets.cloudwatch_dashboard_widget_groups.ec2_instance_endpoint_monitoring, {
            account_name = "hmpps-oem-production"
            search_filter_dimension = {
              name = "type_instance"
              values = [
                "rdgateway1.hmpps-domain.service.justice.gov.uk",
              ]
            }
          }),
          module.baseline_presets.cloudwatch_dashboard_widget_groups.lb,
          module.baseline_presets.cloudwatch_dashboard_widget_groups.ec2,
          module.baseline_presets.cloudwatch_dashboard_widget_groups.ec2_windows,
        ]
      }
      "hmpps-oem-production" = {
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
      "nomis-production" = {
        account_name   = "nomis-production"
        periodOverride = "auto"
        start          = "-PT6H"
        widget_groups = [
          merge(module.baseline_presets.cloudwatch_dashboard_widget_groups.ec2_instance_endpoint_monitoring, {
            account_name = "hmpps-oem-production"
            search_filter_dimension = {
              name = "type_instance"
              values = [
                "c.nomis.az.justice.gov.uk",
                "c.nomis.service.justice.gov.uk",
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
      "nomis-combined-reporting-production" = {
        account_name   = "nomis-combined-reporting-production"
        periodOverride = "auto"
        start          = "-PT6H"
        widget_groups = [
          merge(module.baseline_presets.cloudwatch_dashboard_widget_groups.ec2_instance_endpoint_monitoring, {
            account_name = "hmpps-oem-production"
            search_filter_dimension = {
              name = "type_instance"
              values = [
                "reporting.nomis.az.justice.gov.uk",
              ]
            }
          }),
          module.baseline_presets.cloudwatch_dashboard_widget_groups.lb,
          module.baseline_presets.cloudwatch_dashboard_widget_groups.ec2,
          module.baseline_presets.cloudwatch_dashboard_widget_groups.ec2_linux,
          module.baseline_presets.cloudwatch_dashboard_widget_groups.ec2_instance_linux,
          module.baseline_presets.cloudwatch_dashboard_widget_groups.ec2_instance_oracle_db_with_backup,
          module.baseline_presets.cloudwatch_dashboard_widget_groups.ec2_instance_filesystems,
          module.baseline_presets.cloudwatch_dashboard_widget_groups.ec2_windows,
        ]
      }
      "nomis-data-hub-production" = {
        account_name   = "nomis-data-hub-production"
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
      "oasys-production" = {
        account_name   = "oasys-production"
        periodOverride = "auto"
        start          = "-PT6H"
        widget_groups = [
          merge(module.baseline_presets.cloudwatch_dashboard_widget_groups.ec2_instance_endpoint_monitoring, {
            account_name = "hmpps-oem-production"
            search_filter_dimension = {
              name = "type_instance"
              values = [
                "oasys.service.justice.gov.uk",
                "int.oasys.service.justice.gov.uk",
                "practice.int.oasys.service.justice.gov.uk",
                "training.int.oasys.service.justice.gov.uk",
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
      "oasys-national-reporting-production" = {
        account_name   = "oasys-national-reporting-production"
        periodOverride = "auto"
        start          = "-PT6H"
        widget_groups = [
          merge(module.baseline_presets.cloudwatch_dashboard_widget_groups.ec2_instance_endpoint_monitoring, {
            account_name = "hmpps-oem-production"
            search_filter_dimension = {
              name = "type_instance"
              values = [
                "onr.oasys.az.justice.gov.uk",
              ]
            }
          }),
          module.baseline_presets.cloudwatch_dashboard_widget_groups.ec2,
          module.baseline_presets.cloudwatch_dashboard_widget_groups.ec2_linux,
          module.baseline_presets.cloudwatch_dashboard_widget_groups.ec2_instance_linux,
          module.baseline_presets.cloudwatch_dashboard_widget_groups.ec2_windows,
        ]
      }
      "planetfm-production" = {
        account_name   = "planetfm-production"
        periodOverride = "auto"
        start          = "-PT6H"
        widget_groups = [
          merge(module.baseline_presets.cloudwatch_dashboard_widget_groups.ec2_instance_endpoint_monitoring, {
            account_name = "hmpps-oem-production"
            search_filter_dimension = {
              name = "type_instance"
              values = [
                "cafmtx.planetfm.service.justice.gov.uk",
                "cafmwebx2.planetfm.service.justice.gov.uk",
                "cafmtrainweb.planetfm.service.justice.gov.uk",
              ]
            }
          }),
          module.baseline_presets.cloudwatch_dashboard_widget_groups.network_lb,
          module.baseline_presets.cloudwatch_dashboard_widget_groups.ec2,
          module.baseline_presets.cloudwatch_dashboard_widget_groups.ec2_windows,
        ]
      }
    }

    ec2_instances = {
      prod-oem-a = merge(local.ec2_instances.oem, {
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
            branch = "main"
          })
        })
        tags = merge(local.ec2_instances.oem.tags, {
          oracle-sids = "EMREP PRCVCAT"
        })
      })
    }

    oam_sinks = {
      "CloudWatchMetricOamSink" = {
        resource_types = ["AWS::CloudWatch::Metric"]
        source_account_names = [
          "corporate-staff-rostering-production",
          "hmpps-domain-services-production",
          "nomis-production",
          "nomis-combined-reporting-production",
          "nomis-data-hub-production",
          "oasys-production",
          "oasys-national-reporting-production",
          "planetfm-production",
        ]
      }
    }

    route53_zones = {
      "hmpps-production.modernisation-platform.service.justice.gov.uk" = {
        records = [
          { name = "oem.hmpps-oem", type = "CNAME", ttl = "300", records = ["prod-oem-a.hmpps-oem.hmpps-production.modernisation-platform.service.justice.gov.uk"] },
        ]
      }
    }

    secretsmanager_secrets = {
      "/oracle/oem"              = local.secretsmanager_secrets.oem
      "/oracle/database/EMREP"   = local.secretsmanager_secrets.oem
      "/oracle/database/PRCVCAT" = local.secretsmanager_secrets.oem
    }
  }
}
