locals {

  baseline_presets_production = {
    options = {
      db_backup_lifecycle_rule = "rman_backup_one_month"
      sns_topics = {
        pagerduty_integrations = {
          pagerduty = "corporate-staff-rostering-production"
        }
      }
    }
  }

  # please keep resources in alphabetical order
  baseline_production = {

    cloudwatch_dashboards = {
      "CloudWatch-Default" = {
        periodOverride = "auto"
        start          = "-PT6H"
        widget_groups = [
          module.baseline_presets.cloudwatch_dashboard_widget_groups.network_lb,
          local.cloudwatch_dashboard_widget_groups.all_ec2,
          local.cloudwatch_dashboard_widget_groups.db,
          local.cloudwatch_dashboard_widget_groups.app,
          local.cloudwatch_dashboard_widget_groups.web,
          module.baseline_presets.cloudwatch_dashboard_widget_groups.ssm_command,
        ]
      }
      "Region-12" = {
        periodOverride = "auto"
        start          = "-PT6H"
        widget_groups = [
          merge(module.baseline_presets.cloudwatch_dashboard_widget_groups.network_lb, {
            search_filter_dimension = {
              name   = "LoadBalancer"
              values = ["net/r12-lb/e752b3ad72a3982b"]
            }
          }),
          merge(local.cloudwatch_dashboard_widget_groups.all_windows_ec2, {
            search_filter = {
              ec2_tag = [
                { tag_name = "Name", tag_value = "pd-csr-a-7-a" },
                { tag_name = "Name", tag_value = "pd-csr-a-8-b" },
                { tag_name = "Name", tag_value = "pd-csr-w-1-a" },
                { tag_name = "Name", tag_value = "pd-csr-w-2-b" },
              ]
            }
          }),
          merge(local.cloudwatch_dashboard_widget_groups.app, {
            header_markdown = "## EC2 APP pd-csr-a-7-a"
            search_filter   = { ec2_tag = [{ tag_name = "Name", tag_value = "pd-csr-a-7-a" }, ] }
          }),
          merge(local.cloudwatch_dashboard_widget_groups.app, {
            header_markdown = "## EC2 APP pd-csr-a-8-b"
            search_filter   = { ec2_tag = [{ tag_name = "Name", tag_value = "pd-csr-a-8-b" }, ] }
          }),
          merge(local.cloudwatch_dashboard_widget_groups.web, {
            header_markdown = "## EC2 WEB pd-csr-w-1-a"
            search_filter   = { ec2_tag = [{ tag_name = "Name", tag_value = "pd-csr-w-1-a" }, ] }
          }),
          merge(local.cloudwatch_dashboard_widget_groups.web, {
            header_markdown = "## EC2 WEB pd-csr-w-2-b"
            search_filter   = { ec2_tag = [{ tag_name = "Name", tag_value = "pd-csr-w-2-b" }, ] }
          }),
        ]
      }
      "Region-34" = {
        periodOverride = "auto"
        start          = "-PT6H"
        widget_groups = [
          merge(module.baseline_presets.cloudwatch_dashboard_widget_groups.network_lb, {
            search_filter_dimension = {
              name   = "LoadBalancer"
              values = ["net/r34-lb/eaf7c5256cfab30f"]
            }
          }),
          merge(local.cloudwatch_dashboard_widget_groups.all_windows_ec2, {
            search_filter = {
              ec2_tag = [
                { tag_name = "Name", tag_value = "pd-csr-a-9-a" },
                { tag_name = "Name", tag_value = "pd-csr-a-10-b" },
                { tag_name = "Name", tag_value = "pd-csr-w-3-a" },
                { tag_name = "Name", tag_value = "pd-csr-w-4-b" },
              ]
            }
          }),
          merge(local.cloudwatch_dashboard_widget_groups.app, {
            header_markdown = "## EC2 APP pd-csr-a-9-a"
            search_filter   = { ec2_tag = [{ tag_name = "Name", tag_value = "pd-csr-a-9-a" }, ] }
          }),
          merge(local.cloudwatch_dashboard_widget_groups.app, {
            header_markdown = "## EC2 APP pd-csr-a-10-b"
            search_filter   = { ec2_tag = [{ tag_name = "Name", tag_value = "pd-csr-a-10-b" }, ] }
          }),
          merge(local.cloudwatch_dashboard_widget_groups.web, {
            header_markdown = "## EC2 WEB pd-csr-w-3-a"
            search_filter   = { ec2_tag = [{ tag_name = "Name", tag_value = "pd-csr-w-3-a" }, ] }
          }),
          merge(local.cloudwatch_dashboard_widget_groups.web, {
            header_markdown = "## EC2 WEB pd-csr-w-4-b"
            search_filter   = { ec2_tag = [{ tag_name = "Name", tag_value = "pd-csr-w-4-b" }, ] }
          }),
        ]
      }
      "Region-56" = {
        periodOverride = "auto"
        start          = "-PT6H"
        widget_groups = [
          merge(module.baseline_presets.cloudwatch_dashboard_widget_groups.network_lb, {
            search_filter_dimension = {
              name   = "LoadBalancer"
              values = ["net/r56-lb/4ed053adbc21b30a"]
            }
          }),
          merge(local.cloudwatch_dashboard_widget_groups.all_windows_ec2, {
            search_filter = {
              ec2_tag = [
                { tag_name = "Name", tag_value = "pd-csr-a-11-a" },
                { tag_name = "Name", tag_value = "pd-csr-a-12-b" },
                { tag_name = "Name", tag_value = "pd-csr-w-5-a" },
                { tag_name = "Name", tag_value = "pd-csr-w-6-b" },
              ]
            }
          }),
          merge(local.cloudwatch_dashboard_widget_groups.app, {
            header_markdown = "## EC2 APP pd-csr-a-11-a"
            search_filter   = { ec2_tag = [{ tag_name = "Name", tag_value = "pd-csr-a-11-a" }, ] }
          }),
          merge(local.cloudwatch_dashboard_widget_groups.app, {
            header_markdown = "## EC2 APP pd-csr-a-12-b"
            search_filter   = { ec2_tag = [{ tag_name = "Name", tag_value = "pd-csr-a-12-b" }, ] }
          }),
          merge(local.cloudwatch_dashboard_widget_groups.web, {
            header_markdown = "## EC2 WEB pd-csr-w-5-a"
            search_filter   = { ec2_tag = [{ tag_name = "Name", tag_value = "pd-csr-w-5-a" }, ] }
          }),
          merge(local.cloudwatch_dashboard_widget_groups.web, {
            header_markdown = "## EC2 WEB pd-csr-w-6-b"
            search_filter   = { ec2_tag = [{ tag_name = "Name", tag_value = "pd-csr-w-6-b" }, ] }
          }),
        ]
      }
      "pd-csr-db-a" = {
        periodOverride = "auto"
        start          = "-PT6H"
        widget_groups = [
          {
            width         = 8
            height        = 8
            search_filter = { ec2_tag = [{ tag_name = "Name", tag_value = "pd-csr-db-a" }] }
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
            header_markdown = "## EBS PERFORMANCE"
            width           = 8
            height          = 8
            add_ebs_widgets = { iops = true, throughput = true }
            search_filter   = { ec2_tag = [{ tag_name = "Name", tag_value = "pd-csr-db-a" }] }
            widgets         = []
          }
        ]
      }
      "pd-csr-db-b" = {
        periodOverride = "auto"
        start          = "-PT6H"
        widget_groups = [
          {
            width         = 8
            height        = 8
            search_filter = { ec2_tag = [{ tag_name = "Name", tag_value = "pd-csr-db-b" }] }
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
            search_filter   = { ec2_tag = [{ tag_name = "Name", tag_value = "pd-csr-db-b" }] }
            widgets         = []
          }
        ]
      }
    }

    ec2_instances = {
      pd-csr-db-a = merge(local.ec2_instances.db, {
        config = merge(local.ec2_instances.db.config, {
          ami_name          = "hmpps_ol_8_5_oracledb_19c_release_2023-07-14T15-36-30.795Z"
          availability_zone = "eu-west-2a"
          instance_profile_policies = concat(local.ec2_instances.db.config.instance_profile_policies, [
            "Ec2ProdDatabasePolicy",
          ])
        })
        ebs_volumes = merge(local.ec2_instances.db.ebs_volumes, {
          "/dev/sda1" = { label = "root", size = 30 }
          "/dev/sdb"  = { label = "app", size = 200 } # /u01
          "/dev/sdc"  = { label = "app", size = 500 } # /u02
        })
        ebs_volume_config = merge(local.ec2_instances.db.ebs_volume_config, {
          data  = { total_size = 1500 }
          flash = { total_size = 500 }
        })
        instance = merge(local.ec2_instances.db.instance, {
        })
        tags = merge(local.ec2_instances.db.tags, {
          ami           = "base_ol_8_5"
          description   = "PD CSR Oracle primary DB server"
          pre-migration = "PDCDL00013"
          oracle-sids   = "PIWFM"
        })
      })

      pd-csr-db-b = merge(local.ec2_instances.db, {
        cloudwatch_metric_alarms = merge(
          local.cloudwatch_metric_alarms.db,
          # local.cloudwatch_metric_alarms.db_backup,
        )
        config = merge(local.ec2_instances.db.config, {
          ami_name          = "hmpps_ol_8_5_oracledb_19c_release_2023-07-14T15-36-30.795Z"
          availability_zone = "eu-west-2b"
          instance_profile_policies = concat(local.ec2_instances.db.config.instance_profile_policies, [
            "Ec2ProdDatabasePolicy",
          ])
        })
        ebs_volumes = merge(local.ec2_instances.db.ebs_volumes, {
          "/dev/sda1" = { label = "root", size = 30 }
          "/dev/sdb"  = { label = "app", size = 200 } # /u01
          "/dev/sdc"  = { label = "app", size = 500 } # /u02
        })
        ebs_volume_config = merge(local.ec2_instances.db.ebs_volume_config, {
          data  = { total_size = 1500 }
          flash = { total_size = 500 }
        })
        instance = merge(local.ec2_instances.db.instance, {
        })
        tags = merge(local.ec2_instances.db.tags, {
          ami           = "base_ol_8_5"
          description   = "PD CSR Oracle secondary DB server"
          pre-migration = "PDCDL00014"
          oracle-sids   = "DIWFM"
        })
      })

      pd-csr-a-7-a = merge(local.ec2_instances.app, {
        config = merge(local.ec2_instances.app.config, {
          ami_name          = "pd-csr-a-7-a"
          availability_zone = "eu-west-2a"
        })
        ebs_volumes = {
          "/dev/sda1" = { type = "gp3", size = 128 } # root volume
          "/dev/sdb"  = { type = "gp3", size = 128 }
          "/dev/sdc"  = { type = "gp3", size = 128 }
          "/dev/sdd"  = { type = "gp3", size = 112 }
        }
        instance = merge(local.ec2_instances.app.instance, {
          instance_type = "m5.4xlarge"
        })
        tags = merge(local.ec2_instances.app.tags, {
          ami           = "pd-csr-a-7-a"
          description   = "Application Server Region 1"
          pre-migration = "PDCAW00007"
        })
      })

      pd-csr-a-8-b = merge(local.ec2_instances.app, {
        config = merge(local.ec2_instances.app.config, {
          ami_name          = "pd-csr-a-8-b"
          availability_zone = "eu-west-2b"
        })
        ebs_volumes = {
          "/dev/sda1" = { type = "gp3", size = 128 } # root volume
          "/dev/sdb"  = { type = "gp3", size = 128 }
          "/dev/sdc"  = { type = "gp3", size = 128 }
          "/dev/sdd"  = { type = "gp3", size = 112 }
        }
        instance = merge(local.ec2_instances.app.instance, {
          instance_type = "m5.4xlarge"
        })
        tags = merge(local.ec2_instances.app.tags, {
          ami           = "pd-csr-a-8-b"
          description   = "Application Server Region 2"
          pre-migration = "PDCAW00008"
        })
      })

      pd-csr-a-9-a = merge(local.ec2_instances.app, {
        config = merge(local.ec2_instances.app.config, {
          ami_name          = "pd-csr-a-9-a"
          availability_zone = "eu-west-2a"
        })
        ebs_volumes = {
          "/dev/sda1" = { type = "gp3", size = 128 } # root volume
          "/dev/sdb"  = { type = "gp3", size = 128 }
          "/dev/sdc"  = { type = "gp3", size = 112 }
          "/dev/sdd"  = { type = "gp3", size = 128 }
        }
        instance = merge(local.ec2_instances.app.instance, {
          instance_type = "m5.4xlarge"
        })
        tags = merge(local.ec2_instances.app.tags, {
          ami           = "pd-csr-a-9-a"
          description   = "Application Server Region 3"
          pre-migration = "PDCAW00009"
        })
      })

      pd-csr-a-10-b = merge(local.ec2_instances.app, {
        config = merge(local.ec2_instances.app.config, {
          ami_name          = "pd-csr-a-10-b"
          availability_zone = "eu-west-2b"
        })
        ebs_volumes = {
          "/dev/sda1" = { type = "gp3", size = 128 } # root volume
          "/dev/sdb"  = { type = "gp3", size = 128 }
          "/dev/sdc"  = { type = "gp3", size = 128 }
          "/dev/sdd"  = { type = "gp3", size = 112 }
        }
        instance = merge(local.ec2_instances.app.instance, {
          instance_type = "m5.4xlarge"
        })
        tags = merge(local.ec2_instances.app.tags, {
          ami           = "pd-csr-a-10-b"
          description   = "Application Server Region 4"
          pre-migration = "PDCAW00010"
        })
      })

      pd-csr-a-11-a = merge(local.ec2_instances.app, {
        config = merge(local.ec2_instances.app.config, {
          ami_name          = "pd-csr-a-11-a"
          availability_zone = "eu-west-2a"
        })
        ebs_volumes = {
          "/dev/sda1" = { type = "gp3", size = 128 } # root volume
          "/dev/sdb"  = { type = "gp3", size = 112 }
          "/dev/sdc"  = { type = "gp3", size = 128 }
          "/dev/sdd"  = { type = "gp3", size = 128 }
        }
        instance = merge(local.ec2_instances.app.instance, {
          instance_type = "m5.4xlarge"
        })
        tags = merge(local.ec2_instances.app.tags, {
          ami           = "pd-csr-a-11-a"
          description   = "Application Server Region 5"
          pre-migration = "PDCAW00011"
        })
      })

      pd-csr-a-12-b = merge(local.ec2_instances.app, {
        config = merge(local.ec2_instances.app.config, {
          ami_name          = "pd-csr-a-12-b"
          availability_zone = "eu-west-2b"
        })
        ebs_volumes = {
          "/dev/sda1" = { type = "gp3", size = 128 } # root volume
          "/dev/sdb"  = { type = "gp3", size = 128 }
          "/dev/sdc"  = { type = "gp3", size = 112 }
        }
        instance = merge(local.ec2_instances.app.instance, {
          instance_type = "m5.4xlarge"
        })
        tags = merge(local.ec2_instances.app.tags, {
          ami           = "pd-csr-a-12-b"
          description   = "Application Server Region 6"
          pre-migration = "PDCAW00012"
        })
      })

      pd-csr-w-1-a = merge(local.ec2_instances.web, {
        config = merge(local.ec2_instances.web.config, {
          ami_name          = "pd-csr-w-1-a"
          availability_zone = "eu-west-2a"
        })
        ebs_volumes = {
          "/dev/sda1" = { type = "gp3", size = 128 }
          "/dev/sdb"  = { type = "gp3", size = 128 }
          "/dev/sdc"  = { type = "gp3", size = 128 }
          "/dev/sdd"  = { type = "gp3", size = 112 }
        }
        instance = merge(local.ec2_instances.web.instance, {
          instance_type = "m5.4xlarge"
        })
        tags = merge(local.ec2_instances.web.tags, {
          ami           = "pd-csr-w-1-a"
          description   = "Web Server Region 1 and 2"
          pre-migration = "PDCWW00001"
        })
      })

      pd-csr-w-2-b = merge(local.ec2_instances.web, {
        config = merge(local.ec2_instances.web.config, {
          ami_name          = "pd-csr-w-2-b"
          availability_zone = "eu-west-2b"
        })
        ebs_volumes = {
          "/dev/sda1" = { type = "gp3", size = 128 }
          "/dev/sdb"  = { type = "gp3", size = 128 }
          "/dev/sdc"  = { type = "gp3", size = 128 }
          "/dev/sdd"  = { type = "gp3", size = 112 }
        }
        instance = merge(local.ec2_instances.web.instance, {
          instance_type = "m5.4xlarge"
        })
        tags = merge(local.ec2_instances.web.tags, {
          ami           = "pd-csr-w-2-b"
          description   = "Web Server Region 1 and 2"
          pre-migration = "PDCWW00002"
        })
      })

      pd-csr-w-3-a = merge(local.ec2_instances.web, {
        config = merge(local.ec2_instances.web.config, {
          ami_name          = "pd-csr-w-3-a"
          availability_zone = "eu-west-2a"
        })
        ebs_volumes = {
          "/dev/sda1" = { type = "gp3", size = 128 }
          "/dev/sdb"  = { type = "gp3", size = 128 }
          "/dev/sdc"  = { type = "gp3", size = 112 }
          "/dev/sdd"  = { type = "gp3", size = 128 }
        }
        instance = merge(local.ec2_instances.web.instance, {
          instance_type = "m5.4xlarge"
        })
        tags = merge(local.ec2_instances.web.tags, {
          ami           = "pd-csr-w-3-a"
          description   = "Web Server Region 3 and 4"
          pre-migration = "PDCWW00003"
        })
      })

      pd-csr-w-4-b = merge(local.ec2_instances.web, {
        config = merge(local.ec2_instances.web.config, {
          ami_name          = "pd-csr-w-4-b"
          availability_zone = "eu-west-2b"
        })
        ebs_volumes = {
          "/dev/sda1" = { type = "gp3", size = 128 }
          "/dev/sdb"  = { type = "gp3", size = 112 }
          "/dev/sdc"  = { type = "gp3", size = 128 }
          "/dev/sdd"  = { type = "gp3", size = 128 }
        }
        instance = merge(local.ec2_instances.web.instance, {
          instance_type = "m5.4xlarge"
        })
        tags = merge(local.ec2_instances.web.tags, {
          ami           = "pd-csr-w-4-b"
          description   = "Web Server Region 3 and 4"
          pre-migration = "PDCWW00004"
        })
      })

      pd-csr-w-5-a = merge(local.ec2_instances.web, {
        config = merge(local.ec2_instances.web.config, {
          ami_name          = "pd-csr-w-5-a"
          availability_zone = "eu-west-2a"
        })
        ebs_volumes = {
          "/dev/sda1" = { type = "gp3", size = 128 }
          "/dev/sdb"  = { type = "gp3", size = 128 }
          "/dev/sdc"  = { type = "gp3", size = 112 }
          "/dev/sdd"  = { type = "gp3", size = 128 }
        }
        instance = merge(local.ec2_instances.web.instance, {
          instance_type = "m5.4xlarge"
        })
        tags = merge(local.ec2_instances.web.tags, {
          ami           = "pd-csr-w-5-a"
          description   = "Web Server Region 5 and 6"
          pre-migration = "PDCWW00005"
        })
      })

      pd-csr-w-6-b = merge(local.ec2_instances.web, {
        config = merge(local.ec2_instances.web.config, {
          ami_name          = "pd-csr-w-6-b"
          availability_zone = "eu-west-2b"
        })
        ebs_volumes = {
          "/dev/sda1" = { type = "gp3", size = 128 }
          "/dev/sdb"  = { type = "gp3", size = 128 }
          "/dev/sdc"  = { type = "gp3", size = 128 }
          "/dev/sdd"  = { type = "gp3", size = 112 }
        }
        instance = merge(local.ec2_instances.web.instance, {
          instance_type = "m5.4xlarge"
        })
        tags = merge(local.ec2_instances.web.tags, {
          ami           = "pd-csr-w-6-b"
          description   = "Web Server Region 5 and 6"
          pre-migration = "PDCWW00006"
        })
      })

      prisoner-retail = local.ec2_instances.prisoner-retail
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
              "arn:aws:secretsmanager:*:*:secret:/oracle/database/*P/*",
              "arn:aws:secretsmanager:*:*:secret:/oracle/database/P*/*",
            ]
          }
        ]
      }
      Ec2PrisonerRetailPolicy = {
        description = "Permissions required for prisoner retail"
        statements = [
          {
            effect = "Allow"
            actions = [
              "secretsmanager:GetSecretValue",
              "secretsmanager:PutSecretValue",
            ]
            resources = [
              "arn:aws:secretsmanager:*:*:secret:/prisoner-retail/*",
            ]
          }
        ]
      }
    }

    lbs = {

      r12 = merge(local.lbs.rxy, {
        instance_target_groups = {
          pd-csr-w-12-80 = merge(local.lbs.rxy.instance_target_groups.w-80, {
            attachments = [
              { ec2_instance_name = "pd-csr-w-1-a" },
              { ec2_instance_name = "pd-csr-w-2-b" },
            ]
          })
          pd-csr-w-12-7770 = merge(local.lbs.rxy.instance_target_groups.w-7770, {
            attachments = [
              { ec2_instance_name = "pd-csr-w-1-a" },
              { ec2_instance_name = "pd-csr-w-2-b" },
            ]
          })
          pd-csr-w-12-7771 = merge(local.lbs.rxy.instance_target_groups.w-7771, {
            attachments = [
              { ec2_instance_name = "pd-csr-w-1-a" },
              { ec2_instance_name = "pd-csr-w-2-b" },
            ]
          })
          pd-csr-w-12-7780 = merge(local.lbs.rxy.instance_target_groups.w-7780, {
            attachments = [
              { ec2_instance_name = "pd-csr-w-1-a" },
              { ec2_instance_name = "pd-csr-w-2-b" },
            ]
          })
          pd-csr-w-12-7781 = merge(local.lbs.rxy.instance_target_groups.w-7781, {
            attachments = [
              { ec2_instance_name = "pd-csr-w-1-a" },
              { ec2_instance_name = "pd-csr-w-2-b" },
            ]
          })
        }

        listeners = {
          http = merge(local.lbs.rxy.listeners.http, {
            default_action = {
              type              = "forward"
              target_group_name = "pd-csr-w-12-80"
            }
          })
          http-7770 = merge(local.lbs.rxy.listeners.http-7770, {
            alarm_target_group_names = ["pd-csr-w-12-7770"]
            default_action = {
              type              = "forward"
              target_group_name = "pd-csr-w-12-7770"
            }
          })
          http-7771 = merge(local.lbs.rxy.listeners.http-7771, {
            alarm_target_group_names = ["pd-csr-w-12-7771"]
            default_action = {
              type              = "forward"
              target_group_name = "pd-csr-w-12-7771"
            }
          })
          http-7780 = merge(local.lbs.rxy.listeners.http-7780, {
            alarm_target_group_names = ["pd-csr-w-12-7780"]
            default_action = {
              type              = "forward"
              target_group_name = "pd-csr-w-12-7780"
            }
          })
          http-7781 = merge(local.lbs.rxy.listeners.http-7781, {
            alarm_target_group_names = ["pd-csr-w-12-7781"]
            default_action = {
              type              = "forward"
              target_group_name = "pd-csr-w-12-7781"
            }
          })
        }
      })

      r34 = merge(local.lbs.rxy, {
        instance_target_groups = {
          pd-csr-w-34-80 = merge(local.lbs.rxy.instance_target_groups.w-80, {
            attachments = [
              { ec2_instance_name = "pd-csr-w-3-a" },
              { ec2_instance_name = "pd-csr-w-4-b" },
            ]
          })
          pd-csr-w-34-7770 = merge(local.lbs.rxy.instance_target_groups.w-7770, {
            attachments = [
              { ec2_instance_name = "pd-csr-w-3-a" },
              { ec2_instance_name = "pd-csr-w-4-b" },
            ]
          })
          pd-csr-w-34-7771 = merge(local.lbs.rxy.instance_target_groups.w-7771, {
            attachments = [
              { ec2_instance_name = "pd-csr-w-3-a" },
              { ec2_instance_name = "pd-csr-w-4-b" },
            ]
          })
          pd-csr-w-34-7780 = merge(local.lbs.rxy.instance_target_groups.w-7780, {
            attachments = [
              { ec2_instance_name = "pd-csr-w-3-a" },
              { ec2_instance_name = "pd-csr-w-4-b" },
            ]
          })
          pd-csr-w-34-7781 = merge(local.lbs.rxy.instance_target_groups.w-7781, {
            attachments = [
              { ec2_instance_name = "pd-csr-w-3-a" },
              { ec2_instance_name = "pd-csr-w-4-b" },
            ]
          })
        }

        listeners = {
          http = merge(local.lbs.rxy.listeners.http, {
            default_action = {
              type              = "forward"
              target_group_name = "pd-csr-w-34-80"
            }
          })
          http-7770 = merge(local.lbs.rxy.listeners.http-7770, {
            alarm_target_group_names = ["pd-csr-w-34-7770"]
            default_action = {
              type              = "forward"
              target_group_name = "pd-csr-w-34-7770"
            }
          })
          http-7771 = merge(local.lbs.rxy.listeners.http-7771, {
            alarm_target_group_names = ["pd-csr-w-34-7771"]
            default_action = {
              type              = "forward"
              target_group_name = "pd-csr-w-34-7771"
            }
          })
          http-7780 = merge(local.lbs.rxy.listeners.http-7780, {
            alarm_target_group_names = ["pd-csr-w-34-7780"]
            default_action = {
              type              = "forward"
              target_group_name = "pd-csr-w-34-7780"
            }
          })
          http-7781 = merge(local.lbs.rxy.listeners.http-7781, {
            alarm_target_group_names = ["pd-csr-w-34-7781"]
            default_action = {
              type              = "forward"
              target_group_name = "pd-csr-w-34-7781"
            }
          })
        }
      })

      r56 = merge(local.lbs.rxy, {
        instance_target_groups = {
          pd-csr-w-56-80 = merge(local.lbs.rxy.instance_target_groups.w-80, {
            attachments = [
              { ec2_instance_name = "pd-csr-w-5-a" },
              { ec2_instance_name = "pd-csr-w-6-b" },
            ]
          })
          pd-csr-w-56-7770 = merge(local.lbs.rxy.instance_target_groups.w-7770, {
            attachments = [
              { ec2_instance_name = "pd-csr-w-5-a" },
              { ec2_instance_name = "pd-csr-w-6-b" },
            ]
          })
          pd-csr-w-56-7771 = merge(local.lbs.rxy.instance_target_groups.w-7771, {
            attachments = [
              { ec2_instance_name = "pd-csr-w-5-a" },
              { ec2_instance_name = "pd-csr-w-6-b" },
            ]
          })
          pd-csr-w-56-7780 = merge(local.lbs.rxy.instance_target_groups.w-7780, {
            attachments = [
              { ec2_instance_name = "pd-csr-w-5-a" },
              { ec2_instance_name = "pd-csr-w-6-b" },
            ]
          })
          pd-csr-w-56-7781 = merge(local.lbs.rxy.instance_target_groups.w-7781, {
            attachments = [
              { ec2_instance_name = "pd-csr-w-5-a" },
              { ec2_instance_name = "pd-csr-w-6-b" },
            ]
          })
        }

        listeners = {
          http = merge(local.lbs.rxy.listeners.http, {
            default_action = {
              type              = "forward"
              target_group_name = "pd-csr-w-56-80"
            }
          })
          http-7770 = merge(local.lbs.rxy.listeners.http-7770, {
            alarm_target_group_names = ["pd-csr-w-56-7770"]
            default_action = {
              type              = "forward"
              target_group_name = "pd-csr-w-56-7770"
            }
          })
          http-7771 = merge(local.lbs.rxy.listeners.http-7771, {
            alarm_target_group_names = ["pd-csr-w-56-7771"]
            default_action = {
              type              = "forward"
              target_group_name = "pd-csr-w-56-7771"
            }
          })
          http-7780 = merge(local.lbs.rxy.listeners.http-7780, {
            alarm_target_group_names = ["pd-csr-w-56-7780"]
            default_action = {
              type              = "forward"
              target_group_name = "pd-csr-w-56-7780"
            }
          })
          http-7781 = merge(local.lbs.rxy.listeners.http-7781, {
            alarm_target_group_names = ["pd-csr-w-56-7781"]
            default_action = {
              type              = "forward"
              target_group_name = "pd-csr-w-56-7781"
            }
          })
        }
      })
    }

    route53_zones = {
      "csr.service.justice.gov.uk" = {
        records = [
          { name = "test", type = "NS", ttl = "86400", records = ["ns-1332.awsdns-38.org", "ns-2038.awsdns-62.co.uk", "ns-62.awsdns-07.com", "ns-689.awsdns-22.net"] },
          { name = "pp", type = "NS", ttl = "86400", records = ["ns-1408.awsdns-48.org", "ns-1844.awsdns-38.co.uk", "ns-447.awsdns-55.com", "ns-542.awsdns-03.net"] },
          { name = "piwfm", type = "CNAME", ttl = "300", records = ["pd-csr-db-a.corporate-staff-rostering.hmpps-production.modernisation-platform.service.justice.gov.uk"] },
          { name = "traina", type = "CNAME", ttl = "300", records = ["traina.pp.csr.service.justice.gov.uk"] },
          { name = "trainb", type = "CNAME", ttl = "300", records = ["trainb.pp.csr.service.justice.gov.uk"] },
        ]
        lb_alias_records = [
          { name = "r1", type = "A", lbs_map_key = "r12" },
          { name = "r2", type = "A", lbs_map_key = "r12" },
          { name = "r3", type = "A", lbs_map_key = "r34" },
          { name = "r4", type = "A", lbs_map_key = "r34" },
          { name = "r5", type = "A", lbs_map_key = "r56" },
          { name = "r6", type = "A", lbs_map_key = "r56" },
        ]
      }
    }

    secretsmanager_secrets = {
      "/oracle/database/PIWFM" = {
        secrets = {
          passwords = { description = "database passwords" }
        }
      }
      "/oracle/database/DIWFM" = {
        secrets = {
          passwords = { description = "database passwords" }
        }
      }
      "/prisoner-retail" = {
        secrets = {
          notify_emails = { description = "email list to notify about prisoner retail job outputs. Format: 'from':'some.name@domain','to':'\"<some.name@domain>\", \"<another.name@domain>\" " }
        }
      }
    }
  }
}
