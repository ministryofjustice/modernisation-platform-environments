locals {

  baseline_presets_preproduction = {
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

      enable_ec2_delius_dba_secrets_access = true

      sns_topics = {
        pagerduty_integrations = {
          azure-fixngo-pagerduty              = "az-noms-production-1-alerts"
          corporate-staff-rostering-pagerduty = "corporate-staff-rostering-preproduction"
          dso-pipelines-pagerduty             = "dso-pipelines"
          hmpps-domain-services-pagerduty     = "hmpps-domain-services-preproduction"
          nomis-combined-reporting-pagerduty  = "nomis-combined-reporting-preproduction"
          nomis-pagerduty                     = "nomis-preproduction"
          oasys-national-reporting-pagerduty  = "oasys-national-reporting-preproduction"
          oasys-pagerduty                     = "oasys-preproduction"
          pagerduty                           = "hmpps-oem-preproduction"
          planetfm-pagerduty                  = "planetfm-preproduction"
        }
      }
    }
  }

  # please keep resources in alphabetical order
  baseline_preproduction = {

    cloudwatch_dashboards = {
      "corporate-staff-rostering-preproduction" = {
        account_name   = "corporate-staff-rostering-preproduction"
        periodOverride = "auto"
        start          = "-PT6H"
        widget_groups = [
          merge(module.baseline_presets.cloudwatch_dashboard_widget_groups.ec2_instance_endpoint_monitoring, {
            account_name = "hmpps-oem-preproduction"
            search_filter_dimension = {
              name = "type_instance"
              values = [
                "r1.pp.csr.service.justice.gov.uk",
                "r2.pp.csr.service.justice.gov.uk",
                "r3.pp.csr.service.justice.gov.uk",
                "r4.pp.csr.service.justice.gov.uk",
                "r5.pp.csr.service.justice.gov.uk",
                "r6.pp.csr.service.justice.gov.uk",
                "traina.csr.service.justice.gov.uk",
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
        account_name   = "hmpps-oem-preproduction"
        periodOverride = "auto"
        start          = "-PT6H"
        widget_groups = [
          module.baseline_presets.cloudwatch_dashboard_widget_groups.ec2_instance_endpoint_monitoring,
          module.baseline_presets.cloudwatch_dashboard_widget_groups.ssm_command,
        ]
      }
      "hmpps-domain-services-preproduction" = {
        account_name   = "hmpps-domain-services-preproduction"
        periodOverride = "auto"
        start          = "-PT6H"
        widget_groups = [
          merge(module.baseline_presets.cloudwatch_dashboard_widget_groups.ec2_instance_endpoint_monitoring, {
            account_name = "hmpps-oem-preproduction"
            search_filter_dimension = {
              name = "type_instance"
              values = [
                "rdgateway1.preproduction.hmpps-domain.service.justice.gov.uk",
              ]
            }
          }),
          module.baseline_presets.cloudwatch_dashboard_widget_groups.lb,
          module.baseline_presets.cloudwatch_dashboard_widget_groups.ec2,
          module.baseline_presets.cloudwatch_dashboard_widget_groups.ec2_windows,
        ]
      }
      "hmpps-oem-preproduction" = {
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
      "nomis-preproduction" = {
        account_name   = "nomis-preproduction"
        periodOverride = "auto"
        start          = "-PT6H"
        widget_groups = [
          merge(module.baseline_presets.cloudwatch_dashboard_widget_groups.ec2_instance_endpoint_monitoring, {
            account_name = "hmpps-oem-preproduction"
            search_filter_dimension = {
              name = "type_instance"
              values = [
                "c-lsast.preproduction.nomis.service.justice.gov.uk",
                "c.preproduction.nomis.service.justice.gov.uk",
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
      "nomis-combined-reporting-preproduction" = {
        account_name   = "nomis-combined-reporting-preproduction"
        periodOverride = "auto"
        start          = "-PT6H"
        widget_groups = [
          merge(module.baseline_presets.cloudwatch_dashboard_widget_groups.ec2_instance_endpoint_monitoring, {
            account_name = "hmpps-oem-preproduction"
            search_filter_dimension = {
              name = "type_instance"
              values = [
                "reporting.pp-nomis.az.justice.gov.uk",
                "preproduction.reporting.nomis.service.justice.gov.uk",
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
      "nomis-data-hub-preproduction" = {
        account_name   = "nomis-data-hub-preproduction"
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
      "oasys-preproduction" = {
        account_name   = "oasys-preproduction"
        periodOverride = "auto"
        start          = "-PT6H"
        widget_groups = [
          merge(module.baseline_presets.cloudwatch_dashboard_widget_groups.ec2_instance_endpoint_monitoring, {
            account_name = "hmpps-oem-preproduction"
            search_filter_dimension = {
              name = "type_instance"
              values = [
                "pp.oasys.service.justice.gov.uk",
                "pp-int.oasys.service.justice.gov.uk",
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
      "oasys-national-reporting-preproduction" = {
        account_name   = "oasys-national-reporting-preproduction"
        periodOverride = "auto"
        start          = "-PT6H"
        widget_groups = [
          merge(module.baseline_presets.cloudwatch_dashboard_widget_groups.ec2_instance_endpoint_monitoring, {
            account_name = "hmpps-oem-preproduction"
            search_filter_dimension = {
              name = "type_instance"
              values = [
                "onr.pp-oasys.az.justice.gov.uk",
              ]
            }
          }),
          module.baseline_presets.cloudwatch_dashboard_widget_groups.ec2,
          module.baseline_presets.cloudwatch_dashboard_widget_groups.ec2_linux,
          module.baseline_presets.cloudwatch_dashboard_widget_groups.ec2_instance_linux,
          module.baseline_presets.cloudwatch_dashboard_widget_groups.ec2_windows,
        ]
      }
      "planetfm-preproduction" = {
        account_name   = "planetfm-preproduction"
        periodOverride = "auto"
        start          = "-PT6H"
        widget_groups = [
          merge(module.baseline_presets.cloudwatch_dashboard_widget_groups.ec2_instance_endpoint_monitoring, {
            account_name = "hmpps-oem-preproduction"
            search_filter_dimension = {
              name = "type_instance"
              values = [
                "cafmtx.pp.planetfm.service.justice.gov.uk",
                "cafmwebx.pp.planetfm.service.justice.gov.uk",
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

      preprod-oem-a = merge(local.ec2_instances.oem, {
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
          oracle-sids = "EMREP PPRCVCAT"
        })
      })
    }

    oam_sinks = {
      "CloudWatchMetricOamSink" = {
        resource_types = ["AWS::CloudWatch::Metric"]
        source_account_names = [
          "corporate-staff-rostering-preproduction",
          "hmpps-domain-services-preproduction",
          "nomis-preproduction",
          "nomis-combined-reporting-preproduction",
          "nomis-data-hub-preproduction",
          "oasys-preproduction",
          "oasys-national-reporting-preproduction",
          "planetfm-preproduction",
        ]
      }
    }

    route53_zones = {
      "hmpps-preproduction.modernisation-platform.service.justice.gov.uk" = {
        records = [
          { name = "oem.hmpps-oem", type = "CNAME", ttl = "300", records = ["preprod-oem-a.hmpps-oem.hmpps-preproduction.modernisation-platform.service.justice.gov.uk"] },
        ]
      }
    }

    secretsmanager_secrets = {
      "/oracle/oem"               = local.secretsmanager_secrets.oem
      "/oracle/database/EMREP"    = local.secretsmanager_secrets.oem
      "/oracle/database/PPRCVCAT" = local.secretsmanager_secrets.oem
    }
  }
}
