# nomis-production environment settings
locals {

  lb_maintenance_message_production = {
    maintenance_title   = "Prison-NOMIS Maintenance Window"
    maintenance_message = "Prison-NOMIS is currently unavailable due to planned maintenance. Please try again later"
  }

  baseline_presets_production = {
    options = {
      enable_xsiam_cloudwatch_integration = true
      enable_xsiam_s3_integration         = true
      route53_resolver_rules = {
        outbound-data-and-private-subnets = ["azure-fixngo-domain", "infra-int-domain"]
      }
      sns_topics = {
        pagerduty_integrations = {
          pagerduty = "nomis-production"
        }
      }
    }
  }

  # please keep resources in alphabetical order
  baseline_production = {

    acm_certificates = {
      nomis_wildcard_cert_v3 = {
        cloudwatch_metric_alarms            = module.baseline_presets.cloudwatch_metric_alarms.acm
        domain_name                         = "*.nomis.service.justice.gov.uk"
        external_validation_records_created = true
        subject_alternate_names = [
          "*.nomis.az.justice.gov.uk",
          "*.nomis.hmpps-production.modernisation-platform.service.justice.gov.uk",
          "*.production.nomis.az.justice.gov.uk",
          "*.production.nomis.service.justice.gov.uk",
        ]
        tags = {
          description = "wildcard cert for nomis production domains"
        }
      }
    }

    cloudwatch_dashboards = {
      "CloudWatch-Default" = {
        periodOverride = "auto"
        start          = "-PT6H"
        widget_groups = [
          module.baseline_presets.cloudwatch_dashboard_widget_groups.lb,
          local.cloudwatch_dashboard_widget_groups.connectivity,
          local.cloudwatch_dashboard_widget_groups.db,
          local.cloudwatch_dashboard_widget_groups.xtag,
          local.cloudwatch_dashboard_widget_groups.asg,
          module.baseline_presets.cloudwatch_dashboard_widget_groups.ssm_command,
        ]
      }
      "prod-nomis-db-1-a" = {
        periodOverride = "auto"
        start          = "-PT6H"
        widget_groups = [
          {
            width         = 8
            height        = 8
            search_filter = { ec2_tag = [{ tag_name = "Name", tag_value = "prod-nomis-db-1-a" }] }
            widgets = [
              module.baseline_presets.cloudwatch_dashboard_widgets.ec2.cpu-utilization-high,
              module.baseline_presets.cloudwatch_dashboard_widgets.ec2.network-in-bandwidth,
              module.baseline_presets.cloudwatch_dashboard_widgets.ec2.network-out-bandwidth,
              module.baseline_presets.cloudwatch_dashboard_widgets.ec2.instance-status-check-failed,
              module.baseline_presets.cloudwatch_dashboard_widgets.ec2.system-status-check-failed,
              module.baseline_presets.cloudwatch_dashboard_widgets.ec2.attached-ebs-status-check-failed,
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
          },
          {
            header_markdown = "## NOMIS BATCH"
            width           = 8
            height          = 8
            search_filter   = { ec2_tag = [{ tag_name = "Name", tag_value = "prod-nomis-db-1-a" }] }
            widgets = [
              module.baseline_presets.cloudwatch_dashboard_widgets.ec2_instance_cwagent_collectd_textfile_monitoring.textfile-monitoring-metric-error,
              module.baseline_presets.cloudwatch_dashboard_widgets.ec2_instance_cwagent_collectd_textfile_monitoring.textfile-monitoring-metric-not-updated,
              null
            ]
          },
          {
            header_markdown = "## EBS PERFORMANCE"
            width           = 8
            height          = 8
            add_ebs_widgets = { iops = true, throughput = true }
            search_filter   = { ec2_tag = [{ tag_name = "Name", tag_value = "prod-nomis-db-1-a" }] }
            widgets         = []
          }
        ]
      }
      "prod-nomis-db-1-b" = {
        periodOverride = "auto"
        start          = "-PT6H"
        widget_groups = [
          {
            width         = 8
            height        = 8
            search_filter = { ec2_tag = [{ tag_name = "Name", tag_value = "prod-nomis-db-1-b" }] }
            widgets = [
              module.baseline_presets.cloudwatch_dashboard_widgets.ec2.cpu-utilization-high,
              module.baseline_presets.cloudwatch_dashboard_widgets.ec2.network-in-bandwidth,
              module.baseline_presets.cloudwatch_dashboard_widgets.ec2.network-out-bandwidth,
              module.baseline_presets.cloudwatch_dashboard_widgets.ec2.instance-status-check-failed,
              module.baseline_presets.cloudwatch_dashboard_widgets.ec2.system-status-check-failed,
              module.baseline_presets.cloudwatch_dashboard_widgets.ec2.attached-ebs-status-check-failed,
              module.baseline_presets.cloudwatch_dashboard_widgets.ec2_cwagent_linux.free-disk-space-low,
              module.baseline_presets.cloudwatch_dashboard_widgets.ec2_cwagent_linux.high-memory-usage,
              module.baseline_presets.cloudwatch_dashboard_widgets.ec2_cwagent_linux.cpu-iowait-high,
              module.baseline_presets.cloudwatch_dashboard_widgets.ec2_instance_cwagent_linux.free-disk-space-low,
              module.baseline_presets.cloudwatch_dashboard_widgets.ec2_instance_cwagent_collectd_service_status_os.service-status-error-os-layer,
              module.baseline_presets.cloudwatch_dashboard_widgets.ec2_instance_cwagent_collectd_service_status_app.service-status-error-app-layer,
              module.baseline_presets.cloudwatch_dashboard_widgets.ec2_instance_cwagent_collectd_oracle_db_connected.oracle-db-disconnected,
              null,
              null,
            ]
          },
          {
            header_markdown = "## EBS PERFORMANCE"
            width           = 8
            height          = 8
            add_ebs_widgets = { iops = true, throughput = true }
            search_filter   = { ec2_tag = [{ tag_name = "Name", tag_value = "prod-nomis-db-1-b" }] }
            widgets         = []
          }
        ]
      }
      "prod-nomis-db-2-a" = {
        periodOverride = "auto"
        start          = "-PT6H"
        widget_groups = [
          {
            width         = 8
            height        = 8
            search_filter = { ec2_tag = [{ tag_name = "Name", tag_value = "prod-nomis-db-2-a" }] }
            widgets = [
              module.baseline_presets.cloudwatch_dashboard_widgets.ec2.cpu-utilization-high,
              module.baseline_presets.cloudwatch_dashboard_widgets.ec2.network-in-bandwidth,
              module.baseline_presets.cloudwatch_dashboard_widgets.ec2.network-out-bandwidth,
              module.baseline_presets.cloudwatch_dashboard_widgets.ec2.instance-status-check-failed,
              module.baseline_presets.cloudwatch_dashboard_widgets.ec2.system-status-check-failed,
              module.baseline_presets.cloudwatch_dashboard_widgets.ec2.attached-ebs-status-check-failed,
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
          },
          {
            header_markdown = "## MISLOAD"
            width           = 8
            height          = 8
            search_filter   = { ec2_tag = [{ tag_name = "Name", tag_value = "prod-nomis-db-2-a" }] }
            widgets = [
              module.baseline_presets.cloudwatch_dashboard_widgets.ec2_instance_cwagent_collectd_textfile_monitoring.textfile-monitoring-metric-error,
              module.baseline_presets.cloudwatch_dashboard_widgets.ec2_instance_cwagent_collectd_textfile_monitoring.textfile-monitoring-metric-not-updated,
              null
            ]
          },
          {
            header_markdown = "## EBS PERFORMANCE"
            width           = 8
            height          = 8
            add_ebs_widgets = { iops = true, throughput = true }
            search_filter   = { ec2_tag = [{ tag_name = "Name", tag_value = "prod-nomis-db-2-a" }] }
            widgets         = []
          }
        ]
      }
      "prod-nomis-db-2-b" = {
        periodOverride = "auto"
        start          = "-PT6H"
        widget_groups = [
          {
            width         = 8
            height        = 8
            search_filter = { ec2_tag = [{ tag_name = "Name", tag_value = "prod-nomis-db-2-b" }] }
            widgets = [
              module.baseline_presets.cloudwatch_dashboard_widgets.ec2.cpu-utilization-high,
              module.baseline_presets.cloudwatch_dashboard_widgets.ec2.network-in-bandwidth,
              module.baseline_presets.cloudwatch_dashboard_widgets.ec2.network-out-bandwidth,
              module.baseline_presets.cloudwatch_dashboard_widgets.ec2.instance-status-check-failed,
              module.baseline_presets.cloudwatch_dashboard_widgets.ec2.system-status-check-failed,
              module.baseline_presets.cloudwatch_dashboard_widgets.ec2.attached-ebs-status-check-failed,
              module.baseline_presets.cloudwatch_dashboard_widgets.ec2_cwagent_linux.free-disk-space-low,
              module.baseline_presets.cloudwatch_dashboard_widgets.ec2_cwagent_linux.high-memory-usage,
              module.baseline_presets.cloudwatch_dashboard_widgets.ec2_cwagent_linux.cpu-iowait-high,
              module.baseline_presets.cloudwatch_dashboard_widgets.ec2_instance_cwagent_linux.free-disk-space-low,
              module.baseline_presets.cloudwatch_dashboard_widgets.ec2_instance_cwagent_collectd_service_status_os.service-status-error-os-layer,
              module.baseline_presets.cloudwatch_dashboard_widgets.ec2_instance_cwagent_collectd_service_status_app.service-status-error-app-layer,
              module.baseline_presets.cloudwatch_dashboard_widgets.ec2_instance_cwagent_collectd_oracle_db_connected.oracle-db-disconnected,
              null,
              null,
            ]
          },
          {
            header_markdown = "## EBS PERFORMANCE"
            width           = 8
            height          = 8
            add_ebs_widgets = { iops = true, throughput = true }
            search_filter   = { ec2_tag = [{ tag_name = "Name", tag_value = "prod-nomis-db-2-b" }] }
            widgets         = []
          }
        ]
      }
    }

    ec2_autoscaling_groups = {
      # NOT-ACTIVE (blue deployment)
      prod-nomis-web-a = merge(local.ec2_autoscaling_groups.web, {
        autoscaling_group = merge(local.ec2_autoscaling_groups.web.autoscaling_group, {
          desired_capacity = 0
          max_size         = 0
        })
        # cloudwatch_metric_alarms = local.cloudwatch_metric_alarms.web
        config = merge(local.ec2_autoscaling_groups.web.config, {
          ami_name = "nomis_rhel_6_10_weblogic_appserver_10_3_release_2023-03-15T17-18-22.178Z"
          instance_profile_policies = concat(local.ec2_autoscaling_groups.web.config.instance_profile_policies, [
            "Ec2ProdWeblogicPolicy",
          ])
        })
        instance = merge(local.ec2_autoscaling_groups.web.instance, {
          instance_type = "r4.2xlarge"
        })
        user_data_cloud_init = merge(local.ec2_autoscaling_groups.web.user_data_cloud_init, {
          args = merge(local.ec2_autoscaling_groups.web.user_data_cloud_init.args, {
            branch = "662853f289cc0053f99ba458c3d9d3c4820f3640" # 2025-08-19 crypto requirement fix
          })
        })
        tags = merge(local.ec2_autoscaling_groups.web.tags, {
          nomis-environment    = "prod"
          oracle-db-hostname-a = "pnomis-a.production.nomis.service.justice.gov.uk"
          oracle-db-hostname-b = "pnomis-b.production.nomis.service.justice.gov.uk"
          oracle-db-name       = "PCNOM"
        })
      })

      # ACTIVE (green deployment)
      prod-nomis-web-b = merge(local.ec2_autoscaling_groups.web, {
        autoscaling_group = merge(local.ec2_autoscaling_groups.web.autoscaling_group, {
          desired_capacity = 6
          max_size         = 6

          initial_lifecycle_hooks = {
            "ready-hook" = {
              default_result       = "ABANDON"
              heartbeat_timeout    = 7200
              lifecycle_transition = "autoscaling:EC2_INSTANCE_LAUNCHING"
            }
          }

          # instance_refresh = {
          #   strategy               = "Rolling"
          #   min_healthy_percentage = 80
          # }
        })
        cloudwatch_metric_alarms = local.cloudwatch_metric_alarms.web
        config = merge(local.ec2_autoscaling_groups.web.config, {
          ami_name = "nomis_rhel_6_10_weblogic_appserver_10_3_release_2023-03-15T17-18-22.178Z"
          instance_profile_policies = concat(local.ec2_autoscaling_groups.web.config.instance_profile_policies, [
            "Ec2ProdWeblogicPolicy",
          ])
        })
        instance = merge(local.ec2_autoscaling_groups.web.instance, {
          instance_type = "r4.2xlarge"
        })
        user_data_cloud_init = merge(local.ec2_autoscaling_groups.web.user_data_cloud_init, {
          args = merge(local.ec2_autoscaling_groups.web.user_data_cloud_init.args, {
            # Comment in instance refresh above if changing branch + want automated instance refresh
            branch = "662853f289cc0053f99ba458c3d9d3c4820f3640" # 2025-08-19 crypto requirement fix
          })
        })
        tags = merge(local.ec2_autoscaling_groups.web.tags, {
          nomis-environment    = "prod"
          oracle-db-hostname-a = "pnomis-a.production.nomis.service.justice.gov.uk"
          oracle-db-hostname-b = "pnomis-b.production.nomis.service.justice.gov.uk"
          oracle-db-name       = "PCNOM"
        })
      })

      prod-nomis-client-a = merge(local.ec2_autoscaling_groups.client, {
        tags = merge(local.ec2_autoscaling_groups.client.tags, {
          domain-name = "azure.hmpp.root"
        })
      })
      # Being used for testing, capacity defaults to 0 
      prod-nomis-client-b = merge(local.ec2_autoscaling_groups.client, {
        autoscaling_group = merge(local.ec2_autoscaling_groups.client.autoscaling_group, {
          desired_capacity = 0
          max_size         = 0
        })
        tags = merge(local.ec2_autoscaling_groups.client.tags, {
          domain-name = "azure.hmpp.root"
        })
      })
    }

    ec2_instances = {
      prod-nomis-xtag-a = merge(local.ec2_instances.xtag, {
        cloudwatch_metric_alarms = local.cloudwatch_metric_alarms.xtag
        config = merge(local.ec2_instances.xtag.config, {
          ami_name          = "nomis_rhel_7_9_weblogic_xtag_10_3_release_2023-12-21T17-09-11.541Z"
          availability_zone = "eu-west-2a"
          instance_profile_policies = concat(local.ec2_instances.xtag.config.instance_profile_policies, [
            "Ec2ProdWeblogicPolicy",
          ])
        })
        user_data_cloud_init = merge(local.ec2_instances.xtag.user_data_cloud_init, {
          args = merge(local.ec2_instances.xtag.user_data_cloud_init.args, {
            branch = "main"
          })
        })
        tags = merge(local.ec2_instances.xtag.tags, {
          ndh-ems-hostname     = "pd-ems.ndh.nomis.service.justice.gov.uk"
          nomis-environment    = "prod"
          oracle-db-hostname-a = "pnomis-a.production.nomis.service.justice.gov.uk"
          oracle-db-hostname-b = "pnomis-b.production.nomis.service.justice.gov.uk"
          oracle-db-name       = "PCNOM"
        })
      })

      prod-nomis-db-1-a = merge(local.ec2_instances.db, {
        cloudwatch_metric_alarms = merge(
          local.cloudwatch_metric_alarms.db,
          local.cloudwatch_metric_alarms.db_connected,
          local.cloudwatch_metric_alarms.db_backup,
          local.cloudwatch_metric_alarms.db_nomis_batch,
        )
        config = merge(local.ec2_instances.db.config, {
          ami_name          = "nomis_rhel_7_9_oracledb_11_2_release_2023-07-02T00-00-39.521Z"
          availability_zone = "eu-west-2a"
          instance_profile_policies = concat(local.ec2_instances.db.config.instance_profile_policies, [
            "Ec2ProdDatabasePolicy",
          ])
        })
        ebs_volumes = merge(local.ec2_instances.db.ebs_volumes, {
          "/dev/sdb" = { label = "app", size = 100 }  # /u01
          "/dev/sdc" = { label = "app", size = 1000 } # /u02
        })
        ebs_volume_config = merge(local.ec2_instances.db.ebs_volume_config, {
          data  = { total_size = 4000, iops = 9000, throughput = 300 }
          flash = { total_size = 1000, iops = 3000, throughput = 200 }
        })
        instance = merge(local.ec2_instances.db.instance, {
          disable_api_termination = true
          instance_type           = "r6i.4xlarge"
        })
        tags = merge(local.ec2_instances.db.tags, {
          description       = "Production databases for CNOM and NDH"
          nomis-environment = "prod"
          oracle-sids       = "PDCNOM PDNDH PDTRDAT"
          update-ssm-agent  = "patchgroup2"
        })
      })

      prod-nomis-db-1-b = merge(local.ec2_instances.db, {
        cloudwatch_metric_alarms = merge(
          local.cloudwatch_metric_alarms.db,
          local.cloudwatch_metric_alarms.db_connected,
        )
        config = merge(local.ec2_instances.db.config, {
          ami_name          = "nomis_rhel_7_9_oracledb_11_2_release_2023-07-02T00-00-39.521Z"
          availability_zone = "eu-west-2b"
          instance_profile_policies = concat(local.ec2_instances.db.config.instance_profile_policies, [
            "Ec2ProdDatabasePolicy",
          ])
        })
        ebs_volumes = merge(local.ec2_instances.db.ebs_volumes, {
          "/dev/sdb" = { label = "app", size = 100 }
          "/dev/sdc" = { label = "app", size = 500 }
        })
        ebs_volume_config = merge(local.ec2_instances.db.ebs_volume_config, {
          data  = { total_size = 4000, iops = 9000, throughput = 300 }
          flash = { total_size = 1000, iops = 3000, throughput = 200 }
        })
        instance = merge(local.ec2_instances.db.instance, {
          disable_api_termination = true
          instance_type           = "r6i.4xlarge"
        })
        tags = merge(local.ec2_instances.db.tags, {
          description       = "Disaster-Recovery/High-Availability production databases for CNOM and NDH"
          nomis-environment = "prod"
          oracle-sids       = "DRCNOM DRNDH DRTRDAT"
        })
      })

      prod-nomis-db-2-a = merge(local.ec2_instances.db, {
        cloudwatch_metric_alarms = merge(
          local.cloudwatch_metric_alarms.db,
          local.cloudwatch_metric_alarms.db_connected,
          local.cloudwatch_metric_alarms.db_backup,
          local.cloudwatch_metric_alarms.db_misload,
        )
        config = merge(local.ec2_instances.db.config, {
          ami_name          = "nomis_rhel_7_9_oracledb_11_2_release_2023-07-02T00-00-39.521Z"
          availability_zone = "eu-west-2a"
          instance_profile_policies = concat(local.ec2_instances.db.config.instance_profile_policies, [
            "Ec2ProdDatabasePolicy",
          ])
        })
        ebs_volumes = merge(local.ec2_instances.db.ebs_volumes, {
          "/dev/sdb" = { label = "app", size = 100 }  # /u01
          "/dev/sdc" = { label = "app", size = 1000 } # /u02
        })
        ebs_volume_config = merge(local.ec2_instances.db.ebs_volume_config, {
          data  = { total_size = 6000, iops = 9000, throughput = 300 }
          flash = { total_size = 1000, iops = 3000, throughput = 200 }
        })
        instance = merge(local.ec2_instances.db.instance, {
          disable_api_termination = true
          instance_type           = "r6i.4xlarge"
        })
        tags = merge(local.ec2_instances.db.tags, {
          description       = "Production databases for AUDIT/MIS"
          misload-dbname    = "PDMIS"
          nomis-environment = "prod"
          oracle-sids       = "PDCNMAUD PDMIS"
          update-ssm-agent  = "patchgroup2"
        })
      })

      prod-nomis-db-2-b = merge(local.ec2_instances.db, {
        cloudwatch_metric_alarms = merge(
          local.cloudwatch_metric_alarms.db,
          local.cloudwatch_metric_alarms.db_connected,
          local.cloudwatch_metric_alarms.db_connectivity_test,
        )
        config = merge(local.ec2_instances.db.config, {
          ami_name          = "nomis_rhel_7_9_oracledb_11_2_release_2023-07-02T00-00-39.521Z"
          availability_zone = "eu-west-2b"
          instance_profile_policies = concat(local.ec2_instances.db.config.instance_profile_policies, [
            "Ec2ProdDatabasePolicy",
          ])
        })
        ebs_volumes = merge(local.ec2_instances.db.ebs_volumes, {
          "/dev/sdb" = { label = "app", size = 100 }
          "/dev/sdc" = { label = "app", size = 500 }
        })
        ebs_volume_config = merge(local.ec2_instances.db.ebs_volume_config, {
          data  = { total_size = 6000, iops = 3000, throughput = 125 }
          flash = { total_size = 1000, iops = 3000, throughput = 125 }
          # data  = { total_size = 6000, iops = 9000, throughput = 300 } # replace above with this on failover
          # flash = { total_size = 1000, iops = 3000, throughput = 200 } # replace above with this on failover
        })
        instance = merge(local.ec2_instances.db.instance, {
          disable_api_termination = true
          instance_type           = "r6i.4xlarge"
        })
        tags = merge(local.ec2_instances.db.tags, {
          connectivity-tests = "10.40.0.133:53 10.40.129.79:22"
          description        = "Disaster-Recovery/High-Availability production databases for AUDIT/MIS"
          misload-dbname     = "DRMIS"
          nomis-environment  = "prod"
          oracle-sids        = "DRMIS DRCNMAUD"
        })
      })
    }

    iam_policies = {
      Ec2ProdDatabasePolicy = {
        description = "Permissions required for prod Database EC2s"
        statements = [
          {
            effect = "Allow"
            actions = [
              "secretsmanager:GetSecretValue",
              "secretsmanager:PutSecretValue",
            ]
            resources = [
              "arn:aws:secretsmanager:*:*:secret:/oracle/database/P*/*",
              "arn:aws:secretsmanager:*:*:secret:/oracle/database/DR*/*",
            ]
          }
        ]
      }
      Ec2ProdWeblogicPolicy = {
        description = "Permissions required for prod Weblogic EC2s"
        statements = concat(local.iam_policy_statements_ec2.web, [
          {
            effect = "Allow"
            actions = [
              "secretsmanager:GetSecretValue",
              "secretsmanager:PutSecretValue",
            ]
            resources = [
              "arn:aws:secretsmanager:*:*:secret:/oracle/weblogic/prod/*",
              "arn:aws:secretsmanager:*:*:secret:/oracle/database/P*/weblogic-*",
              "arn:aws:secretsmanager:*:*:secret:/oracle/database/DR*/weblogic-*",
            ]
          }
        ])
      }
    }

    lbs = {
      private = merge(local.lbs.private, {
        access_logs_lifecycle_rule = [module.baseline_presets.s3_lifecycle_rules.general_purpose_one_year]

        s3_notification_queues = {
          "cortex-xsiam-s3-alb-log-collection" = {
            events    = ["s3:ObjectCreated:*"]
            queue_arn = "cortex-xsiam-s3-alb-log-collection"
          }
        }

        listeners = merge(local.lbs.private.listeners, {
          https = merge(local.lbs.private.listeners.https, {
            certificate_names_or_arns = ["nomis_wildcard_cert_v3"]

            alarm_target_group_names = [
              # "prod-nomis-web-a-http-7777",
              "prod-nomis-web-b-http-7777",
            ]

            # /home/oracle/admin/scripts/lb_maintenance_mode.sh script on
            # weblogic servers can alter priorities to enable maintenance message
            rules = {
              prod-nomis-web-a-http-7777 = {
                priority = 200
                actions = [{
                  type              = "forward"
                  target_group_name = "prod-nomis-web-a-http-7777"
                }]
                conditions = [{
                  host_header = {
                    values = [
                      "prod-nomis-web-a.production.nomis.service.justice.gov.uk",
                      "c.production.nomis.az.justice.gov.uk"
                    ]
                  }
                }]
              }
              prod-nomis-web-b-http-7777 = {
                priority = 400
                actions = [{
                  type              = "forward"
                  target_group_name = "prod-nomis-web-b-http-7777"
                }]
                conditions = [{
                  host_header = {
                    values = [
                      "prod-nomis-web-b.production.nomis.service.justice.gov.uk",
                      "c.nomis.service.justice.gov.uk",
                      "c.nomis.az.justice.gov.uk",
                    ]
                  }
                }]
              }

              maintenance = {
                priority = 999
                actions = [{
                  type = "fixed-response"
                  fixed_response = {
                    content_type = "text/html"
                    message_body = templatefile("templates/maintenance.html.tftpl", local.lb_maintenance_message_production)
                    status_code  = "200"
                  }
                }]
                conditions = [{
                  host_header = {
                    values = [
                      "maintenance.production.nomis.service.justice.gov.uk",
                      "prod-nomis-web-a.production.nomis.service.justice.gov.uk",
                      "prod-nomis-web-b.production.nomis.service.justice.gov.uk",
                      "c.nomis.service.justice.gov.uk",
                      "c.nomis.az.justice.gov.uk",
                    ]
                  }
                }]
              }
            }
          })
        })
      })
    }

    route53_zones = {

      "nomis.service.justice.gov.uk" = {
        lb_alias_records = [
          { name = "c", type = "A", lbs_map_key = "private" },
        ]
        ns_records = [
          # use this if NS records can be pulled from terrafrom, otherwise use records variable
          { name = "production", ttl = "86400", zone_name = "production.nomis.service.justice.gov.uk" }
        ]
        records = [
          { name = "development", type = "NS", ttl = "86400", records = ["ns-1010.awsdns-62.net", "ns-1353.awsdns-41.org", "ns-1693.awsdns-19.co.uk", "ns-393.awsdns-49.com"] },
          { name = "test", type = "NS", ttl = "86400", records = ["ns-1423.awsdns-49.org", "ns-1921.awsdns-48.co.uk", "ns-304.awsdns-38.com", "ns-747.awsdns-29.net"] },
          { name = "preproduction", type = "NS", ttl = "86400", records = ["ns-1200.awsdns-22.org", "ns-1958.awsdns-52.co.uk", "ns-44.awsdns-05.com", "ns-759.awsdns-30.net"] },
          { name = "reporting", type = "NS", ttl = "86400", records = ["ns-1122.awsdns-12.org", "ns-1844.awsdns-38.co.uk", "ns-388.awsdns-48.com", "ns-887.awsdns-46.net"] },
          { name = "ndh", type = "NS", ttl = "86400", records = ["ns-1106.awsdns-10.org", "ns-1904.awsdns-46.co.uk", "ns-44.awsdns-05.com", "ns-799.awsdns-35.net"] },
        ]
      }

      # use this zone for testing as it's in the IE compatibility enterprise site list
      "production.nomis.az.justice.gov.uk" = {
        lb_alias_records = [
          { name = "c", type = "A", lbs_map_key = "private" },
        ]
      }

      "production.nomis.service.justice.gov.uk" = {
        records = [
          { name = "pnomis", type = "CNAME", ttl = "300", records = ["prod-nomis-db-1-a.nomis.hmpps-production.modernisation-platform.service.justice.gov.uk"] },
          { name = "pnomis-a", type = "CNAME", ttl = "300", records = ["prod-nomis-db-1-a.nomis.hmpps-production.modernisation-platform.service.justice.gov.uk"] },
          { name = "pnomis-b", type = "CNAME", ttl = "300", records = ["prod-nomis-db-1-b.nomis.hmpps-production.modernisation-platform.service.justice.gov.uk"] },
          { name = "pndh", type = "CNAME", ttl = "300", records = ["prod-nomis-db-1-a.nomis.hmpps-production.modernisation-platform.service.justice.gov.uk"] },
          { name = "pndh-a", type = "CNAME", ttl = "300", records = ["prod-nomis-db-1-a.nomis.hmpps-production.modernisation-platform.service.justice.gov.uk"] },
          { name = "pndh-b", type = "CNAME", ttl = "300", records = ["prod-nomis-db-1-b.nomis.hmpps-production.modernisation-platform.service.justice.gov.uk"] },
          { name = "por", type = "CNAME", ttl = "300", records = ["prod-nomis-db-1-b.nomis.hmpps-production.modernisation-platform.service.justice.gov.uk"] },
          { name = "por-a", type = "CNAME", ttl = "300", records = ["prod-nomis-db-1-b.nomis.hmpps-production.modernisation-platform.service.justice.gov.uk"] },
          { name = "por-b", type = "CNAME", ttl = "300", records = ["prod-nomis-db-1-a.nomis.hmpps-production.modernisation-platform.service.justice.gov.uk"] },
          { name = "ptrdat", type = "CNAME", ttl = "300", records = ["prod-nomis-db-1-a.nomis.hmpps-production.modernisation-platform.service.justice.gov.uk"] },
          { name = "ptrdat-a", type = "CNAME", ttl = "300", records = ["prod-nomis-db-1-a.nomis.hmpps-production.modernisation-platform.service.justice.gov.uk"] },
          { name = "ptrdat-b", type = "CNAME", ttl = "300", records = ["prod-nomis-db-1-b.nomis.hmpps-production.modernisation-platform.service.justice.gov.uk"] },
          { name = "paudit", type = "CNAME", ttl = "300", records = ["prod-nomis-db-2-a.nomis.hmpps-production.modernisation-platform.service.justice.gov.uk"] },
          { name = "paudit-a", type = "CNAME", ttl = "300", records = ["prod-nomis-db-2-a.nomis.hmpps-production.modernisation-platform.service.justice.gov.uk"] },
          { name = "paudit-b", type = "CNAME", ttl = "300", records = ["prod-nomis-db-2-b.nomis.hmpps-production.modernisation-platform.service.justice.gov.uk"] },
          { name = "pmis", type = "CNAME", ttl = "300", records = ["prod-nomis-db-2-a.nomis.hmpps-production.modernisation-platform.service.justice.gov.uk"] },
          { name = "pmis-a", type = "CNAME", ttl = "300", records = ["prod-nomis-db-2-a.nomis.hmpps-production.modernisation-platform.service.justice.gov.uk"] },
          { name = "pmis-b", type = "CNAME", ttl = "300", records = ["prod-nomis-db-2-b.nomis.hmpps-production.modernisation-platform.service.justice.gov.uk"] },
          { name = "pnomisapiro", type = "CNAME", ttl = "300", records = ["prod-nomis-db-1-a.nomis.hmpps-production.modernisation-platform.service.justice.gov.uk"] },
          { name = "pnomisapiro-a", type = "CNAME", ttl = "300", records = ["prod-nomis-db-1-a.nomis.hmpps-production.modernisation-platform.service.justice.gov.uk"] },
          { name = "pnomisapiro-b", type = "CNAME", ttl = "300", records = ["prod-nomis-db-1-b.nomis.hmpps-production.modernisation-platform.service.justice.gov.uk"] },
        ]
        lb_alias_records = [
          { name = "maintenance", type = "A", lbs_map_key = "private" },
          { name = "prod-nomis-web-a", type = "A", lbs_map_key = "private" },
          { name = "prod-nomis-web-b", type = "A", lbs_map_key = "private" },
          { name = "c", type = "A", lbs_map_key = "private" },
        ]
      }
    }

    s3_buckets = {
      nomis-audit-archives = {
        bucket_policy_v2 = [
          module.baseline_presets.s3_bucket_policies.ProdPreprodEnvironmentsReadOnlyAccessBucketPolicy,
        ]
        custom_kms_key = module.environment.kms_keys["general"].arn
        iam_policies   = module.baseline_presets.s3_iam_policies
        lifecycle_rule = [
          module.baseline_presets.s3_lifecycle_rules.ninety_day_standard_ia_ten_year_expiry
        ]
        tags = {
          backup = "false"
        }
      }
    }

    secretsmanager_secrets = {
      "/oracle/weblogic/prod"  = local.secretsmanager_secrets.web
      "/oracle/database/PCNOM" = local.secretsmanager_secrets.db_pcnom # weblogic oracle-db-name set to PCNOM
      # PROD ACTIVE
      "/oracle/database/PDCNOM"   = local.secretsmanager_secrets.db
      "/oracle/database/PDNDH"    = local.secretsmanager_secrets.db
      "/oracle/database/PDTRDAT"  = local.secretsmanager_secrets.db
      "/oracle/database/PDCNMAUD" = local.secretsmanager_secrets.db
      "/oracle/database/PDMIS"    = local.secretsmanager_secrets.db_mis
      # PROD STANDBY
      "/oracle/database/DRCNOM"   = local.secretsmanager_secrets.db
      "/oracle/database/DRNDH"    = local.secretsmanager_secrets.db
      "/oracle/database/DRTRDAT"  = local.secretsmanager_secrets.db
      "/oracle/database/DRCNMAUD" = local.secretsmanager_secrets.db
      "/oracle/database/DRMIS"    = local.secretsmanager_secrets.db_mis
    }
  }
}
