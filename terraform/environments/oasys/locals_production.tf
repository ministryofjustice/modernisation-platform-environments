locals {

  web_live_side = "b"

  baseline_presets_production = {
    options = {
      db_backup_lifecycle_rule            = "rman_backup_one_month"
      enable_xsiam_cloudwatch_integration = true
      enable_xsiam_s3_integration         = true

      sns_topics = {
        pagerduty_integrations = {
          pagerduty = "oasys-production"
        }
      }
    }
  }

  baseline_production = {

    # If your DNS records are in Fix 'n' Go, setup will be a 2 step process, see the acm_certificate module readme
    # if making changes, comment out the listeners that use the cert, edit the cert, recreate the listeners
    acm_certificates = {
      pd_oasys_cert = {
        cloudwatch_metric_alarms            = module.baseline_presets.cloudwatch_metric_alarms.acm
        domain_name                         = "oasys.service.justice.gov.uk"
        external_validation_records_created = true
        subject_alternate_names = [
          "*.oasys.service.justice.gov.uk",
          "*.int.oasys.service.justice.gov.uk",
          "bridge-oasys.az.justice.gov.uk",
          "oasys.az.justice.gov.uk",
          "p-oasys.az.justice.gov.uk",
          "*.oasys.az.justice.gov.uk",
          "*.bridge-oasys.az.justice.gov.uk",
          "*.p-oasys.az.justice.gov.uk",
        ]
        tags = {
          description = "cert for oasys ${local.environment} domains"
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
          local.cloudwatch_dashboard_widget_groups.onr,
          local.cloudwatch_dashboard_widget_groups.ec2,
          module.baseline_presets.cloudwatch_dashboard_widget_groups.ssm_command,
        ]
      }
      "pd-oasys-db-a" = {
        periodOverride = "auto"
        start          = "-PT6H"
        widget_groups = [
          {
            width         = 8
            height        = 8
            search_filter = { ec2_tag = [{ tag_name = "Name", tag_value = "pd-oasys-db-a" }] }
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
            header_markdown = "## OASys BATCH"
            width           = 8
            height          = 8
            search_filter   = { ec2_tag = [{ tag_name = "Name", tag_value = "pd-oasys-db-a" }] }
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
            search_filter   = { ec2_tag = [{ tag_name = "Name", tag_value = "pd-oasys-db-a" }] }
            widgets         = []
          }
        ]
      }
      "pd-oasys-db-b" = {
        periodOverride = "auto"
        start          = "-PT6H"
        widget_groups = [
          {
            width         = 8
            height        = 8
            search_filter = { ec2_tag = [{ tag_name = "Name", tag_value = "pd-oasys-db-b" }] }
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
            header_markdown = "## Other"
            width           = 8
            height          = 8
            search_filter   = { ec2_tag = [{ tag_name = "Name", tag_value = "pd-oasys-db-b" }] }
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
            search_filter   = { ec2_tag = [{ tag_name = "Name", tag_value = "pd-oasys-db-b" }] }
            widgets         = []
          }
        ]
      }
    }

    ec2_autoscaling_groups = {
      pd-oasys-web-a = merge(local.ec2_autoscaling_groups.web, {
        autoscaling_group = merge(local.ec2_autoscaling_groups.web.autoscaling_group, {
          desired_capacity = 0
          max_size         = 0
        })
        config = merge(local.ec2_autoscaling_groups.web.config, {
          instance_profile_policies = concat(local.ec2_autoscaling_groups.web.config.instance_profile_policies, [
            "Ec2ProdWebPolicy",
          ])
        })
        tags = merge(local.ec2_autoscaling_groups.web.tags, {
          oasys-environment  = "production"
          oracle-db-hostname = "db.oasys.hmpps-production.modernisation-platform.internal"
          oracle-db-sid      = "PDOASYS"
        })
      })

      pd-oasys-web-b = merge(local.ec2_autoscaling_groups.web, {
        autoscaling_group = merge(local.ec2_autoscaling_groups.web.autoscaling_group, {
          desired_capacity = 4
          max_size         = 4
        })
        config = merge(local.ec2_autoscaling_groups.web.config, {
          instance_profile_policies = concat(local.ec2_autoscaling_groups.web.config.instance_profile_policies, [
            "Ec2ProdWebPolicy",
          ])
        })
        instance = merge(local.ec2_autoscaling_groups.web.instance, {
          instance_type = "t3.large"
        })
        tags = merge(local.ec2_autoscaling_groups.web.tags, {
          oasys-environment  = "production"
          oracle-db-hostname = "db.oasys.hmpps-production.modernisation-platform.internal"
          oracle-db-sid      = "PDOASYS"
        })
      })

      ptc-oasys-web-a = merge(local.ec2_autoscaling_groups.web, {
        config = merge(local.ec2_autoscaling_groups.web.config, {
          iam_resource_names_prefix = "ec2-web-ptc"
          instance_profile_policies = concat(local.ec2_autoscaling_groups.web.config.instance_profile_policies, [
            "Ec2PtcWebPolicy",
          ])
        })
        instance = merge(local.ec2_autoscaling_groups.web.instance, {
          instance_type           = "t3.medium"
          #instance_type           = "t3.small"
        })
        tags = merge(local.ec2_autoscaling_groups.web.tags, {
          description        = "${local.environment} practice oasys web"
          oasys-environment  = "ptc"
          oracle-db-sid      = "PROASYS"
          oracle-db-hostname = "db.ptc.oasys.hmpps-production.modernisation-platform.internal"
        })
      })

      trn-oasys-web-a = merge(local.ec2_autoscaling_groups.web, {
        config = merge(local.ec2_autoscaling_groups.web.config, {
          iam_resource_names_prefix = "ec2-web-trn"
          instance_profile_policies = concat(local.ec2_autoscaling_groups.web.config.instance_profile_policies, [
            "Ec2TrnWebPolicy",
          ])
        })
        instance = merge(local.ec2_autoscaling_groups.web.instance, {
          instance_type           = "t3.medium"
          #instance_type           = "t3.small"
        })
        tags = merge(local.ec2_autoscaling_groups.web.tags, {
          description        = "${local.environment} training oasys web"
          oasys-environment  = "trn"
          oracle-db-sid      = "TROASYS"
          oracle-db-hostname = "db.trn.oasys.hmpps-production.modernisation-platform.internal"
        })
      })
    }

    ec2_instances = {
      pd-oasys-bip-a = merge(local.ec2_instances.bip, {
        config = merge(local.ec2_instances.bip.config, {
          availability_zone = "eu-west-2a"
          instance_profile_policies = concat(local.ec2_instances.bip.config.instance_profile_policies, [
            "Ec2ProdBipPolicy",
          ])
        })
        instance = merge(local.ec2_instances.bip.instance, {
          ami = "ami-0d206b8546ea2b68a" # to prevent instances being re-created due to recreated AMI
          instance_type = "t3.xlarge" # OVERSIZED
        })
        tags = merge(local.ec2_instances.bip.tags, {
          bip-db-name       = "PDBIPINF"
          bip-db-hostname   = "pd-oasys-db-a"
          oasys-db-name     = "PDOASYS"
          oasys-db-hostname = "pd-oasys-db-a"
          oasys-environment = "production"
        })
      })

      pd-oasys-db-a = merge(local.ec2_instances.db19c, {
        cloudwatch_metric_alarms = merge(local.ec2_instances.db19c.cloudwatch_metric_alarms, {
          cpu-iowait-high = merge(module.baseline_presets.cloudwatch_metric_alarms.ec2_cwagent_linux["cpu-iowait-high"], {
            evaluation_periods  = "15"
            datapoints_to_alarm = "15"
            threshold           = "50"
            alarm_description   = "Triggers if the amount of CPU time spent waiting for I/O to complete is continually high for 15 minutes. See https://dsdmoj.atlassian.net/wiki/spaces/DSTT/pages/4325900634"
          })
        })
        config = merge(local.ec2_instances.db19c.config, {
          availability_zone = "eu-west-2a"
          instance_profile_policies = concat(local.ec2_instances.db19c.config.instance_profile_policies, [
            "Ec2ProdDatabasePolicy",
          ])
        })
        ebs_volumes = {
          "/dev/sdb" = { label = "app", size = 200 }  # /u01
          "/dev/sdc" = { label = "app", size = 1000 } # /u02
          "/dev/sde" = { label = "data", size = 2000, iops = 12000, throughput = 750 }
          "/dev/sdf" = { label = "data", size = 2000, iops = 12000, throughput = 750 }
          "/dev/sdj" = { label = "flash", size = 1000, iops = 5000, throughput = 500 }
          "/dev/sds" = { label = "swap", size = 2 }
        }
        instance = merge(local.ec2_instances.db19c.instance, {
          disable_api_termination = true
          instance_type           = "r6i.4xlarge"
        })
        tags = merge(local.ec2_instances.db19c.tags, {
          bip-db-name       = "PDBIPINF"
          oasys-environment = "production"
          oracle-sids       = "PDBIPINF PDOASYS"
          update-ssm-agent  = "patchgroup1"
        })
      })

      pd-oasys-db-b = merge(local.ec2_instances.db19c, {
        cloudwatch_metric_alarms = merge(local.cloudwatch_metric_alarms.db, {
          cpu-iowait-high = merge(module.baseline_presets.cloudwatch_metric_alarms.ec2_cwagent_linux["cpu-iowait-high"], {
            evaluation_periods  = "15"
            datapoints_to_alarm = "15"
            threshold           = "50"
            alarm_description   = "Triggers if the amount of CPU time spent waiting for I/O to complete is continually high for 15 minutes. See https://dsdmoj.atlassian.net/wiki/spaces/DSTT/pages/4325900634"
          })
        })
        config = merge(local.ec2_instances.db19c.config, {
          availability_zone = "eu-west-2b"
          instance_profile_policies = concat(local.ec2_instances.db19c.config.instance_profile_policies, [
            "Ec2ProdDatabasePolicy",
          ])
        })
        ebs_volumes = {
          "/dev/sdb" = { label = "app", size = 200 }  # /u01
          "/dev/sdc" = { label = "app", size = 1000 } # /u02
          "/dev/sde" = { label = "data", size = 2000, iops = 12000, throughput = 750 }
          "/dev/sdf" = { label = "data", size = 2000, iops = 12000, throughput = 750 }
          "/dev/sdj" = { label = "flash", size = 1000, iops = 5000, throughput = 500 }
          "/dev/sds" = { label = "swap", size = 2 }
        }
        instance = merge(local.ec2_instances.db19c.instance, {
          disable_api_termination = true
          instance_type           = "r6i.4xlarge"
        })
        tags = merge(local.ec2_instances.db19c.tags, {
          bip-db-name       = "PDBIPINF"
          oasys-environment = "production"
          oracle-sids       = "DROASYS"
          update-ssm-agent  = "patchgroup2"
        })
      })

      pd-onr-db-a = merge(local.ec2_instances.db11g, {
        config = merge(local.ec2_instances.db11g.config, {
          availability_zone = "eu-west-2a"
          instance_profile_policies = concat(local.ec2_instances.db11g.config.instance_profile_policies, [
            "Ec2ProdDatabasePolicy",
          ])
        })
        ebs_volumes = {
          "/dev/sdb" = { label = "app", size = 100 } # /u01
          "/dev/sdc" = { label = "app", size = 500 } # /u02
          "/dev/sde" = { label = "data", size = 2000 }
          "/dev/sdj" = { label = "flash", size = 600 }
          "/dev/sds" = { label = "swap", size = 2 }
        }
        instance = merge(local.ec2_instances.db19c.instance, {
          disable_api_termination = true
          instance_type           = "r6i.4xlarge"
        })
        tags = merge(local.ec2_instances.db11g.tags, {
          oasys-environment = "production"
          oracle-sids       = "PDMISTRN PDONRBDS PDONRSYS PDONRAUD PDOASREP"
        })
      })

      ptctrn-oasys-db-a = merge(local.ec2_instances.db19c, {
        config = merge(local.ec2_instances.db19c.config, {
          availability_zone = "eu-west-2a"
          instance_profile_policies = concat(local.ec2_instances.db19c.config.instance_profile_policies, [
            "Ec2PtcTrnDatabasePolicy",
          ])
        })
        instance = merge(local.ec2_instances.db19c.instance, {
          disable_api_termination = true
          instance_type           = "r6i.xlarge"
        })
        ebs_volumes = {
          "/dev/sdb" = { label = "app", size = 200 }   # /u01
          "/dev/sdc" = { label = "app", size = 500 }   # /u02
          "/dev/sde" = { label = "data", size = 300 }  # DATA01
          "/dev/sdj" = { label = "flash", size = 200 } # FLASH01
          "/dev/sds" = { label = "swap", size = 2 }
        }
        tags = merge(local.ec2_instances.db19c.tags, {
          bip-db-name       = "TRBIPINF"
          description       = "practice and training oasys database"
          oasys-environment = "ptctrn"
          oracle-sids       = "PROASYS TROASYS TRBIPINF"
        })
      })

      trn-oasys-bip-a = merge(local.ec2_instances.bip, {
        config = merge(local.ec2_instances.bip.config, {
          availability_zone = "eu-west-2a"
          instance_profile_policies = concat(local.ec2_instances.bip.config.instance_profile_policies, [
            "Ec2TrnBipPolicy",
          ])
        })
        instance = merge(local.ec2_instances.bip.instance, {
          disable_api_termination = true
          instance_type           = "m7i.large"
          ami                     = "ami-0d206b8546ea2b68a" # to prevent instances being re-created due to recreated AMI
        })
        tags = merge(local.ec2_instances.bip.tags, {
          bip-db-hostname   = "ptctrn-oasys-db-a"
          bip-db-name       = "TRBIPINF"
          oasys-db-hostname = "ptctrn-oasys-db-a"
          oasys-db-name     = "TROASYS"
          oasys-environment = "trn"
        })
      })
    }

    iam_policies = {
      Ec2ProdBipPolicy = {
        description = "Permissions required for prod Bip EC2s"
        statements = [
          {
            effect = "Allow"
            actions = [
              "secretsmanager:GetSecretValue",
            ]
            resources = [
              "arn:aws:secretsmanager:*:*:secret:/oracle/database/*PD/bip-*",
              "arn:aws:secretsmanager:*:*:secret:/oracle/database/PD*/bip-*",
              "arn:aws:secretsmanager:*:*:secret:/oracle/bip/production/*",
            ]
          }
        ]
      }
      Ec2ProdDatabasePolicy = {
        description = "Permissions required for Prod Database EC2s"
        statements = [
          {
            effect = "Allow"
            actions = [
              "s3:GetBucketLocation",
              "s3:GetObject",
              "s3:GetObjectTagging",
              "s3:ListBucket",
              "s3:PutObject",
              "s3:PutObjectAcl",
              "s3:PutObjectTagging",
              "s3:DeleteObject",
              "s3:RestoreObject",
            ]
            resources = [
              "arn:aws:s3:::prod-oasys-db-backup-bucket*",
              "arn:aws:s3:::prod-oasys-db-backup-bucket*/*",
            ]
          },
          {
            effect = "Allow"
            actions = [
              "secretsmanager:GetSecretValue",
              "secretsmanager:PutSecretValue",
            ]
            resources = [
              "arn:aws:secretsmanager:*:*:secret:/oracle/database/*PD/*",
              "arn:aws:secretsmanager:*:*:secret:/oracle/database/PD*/*",
              "arn:aws:secretsmanager:*:*:secret:/oracle/database/DR*/*",
            ]
          },
        ]
      }
      Ec2ProdWebPolicy = {
        description = "Permissions required for Prod Web EC2s"
        statements = [
          {
            effect = "Allow"
            actions = [
              "secretsmanager:GetSecretValue",
            ]
            resources = [
              "arn:aws:secretsmanager:*:*:secret:/oracle/database/PDOASYS/apex-passwords*",
              "arn:aws:secretsmanager:*:*:secret:/oracle/database/OASPROD/apex-passwords*",
            ]
          }
        ]
      }

      Ec2PtcTrnDatabasePolicy = {
        description = "Permissions required for practice and training Database EC2s"
        statements = [
          {
            effect = "Allow"
            actions = [
              "s3:GetBucketLocation",
              "s3:GetObject",
              "s3:GetObjectTagging",
              "s3:ListBucket",
              "s3:PutObject",
              "s3:PutObjectAcl",
              "s3:PutObjectTagging",
              "s3:DeleteObject",
              "s3:RestoreObject",
            ]
            resources = [
              "arn:aws:s3:::prod-oasys-db-backup-bucket*",
              "arn:aws:s3:::prod-oasys-db-backup-bucket*/*",
            ]
          },
          {
            effect = "Allow"
            actions = [
              "secretsmanager:GetSecretValue",
              "secretsmanager:PutSecretValue",
            ]
            resources = [
              "arn:aws:secretsmanager:*:*:secret:/oracle/database/*PR/*",
              "arn:aws:secretsmanager:*:*:secret:/oracle/database/PR*/*",
              "arn:aws:secretsmanager:*:*:secret:/oracle/database/*TR/*",
              "arn:aws:secretsmanager:*:*:secret:/oracle/database/TR*/*",
            ]
          },
        ]
      }

      Ec2PtcWebPolicy = {
        description = "Permissions required for practice Web EC2s"
        statements = [
          {
            effect = "Allow"
            actions = [
              "secretsmanager:GetSecretValue",
            ]
            resources = [
              "arn:aws:secretsmanager:*:*:secret:/oracle/database/PROASYS/apex-passwords*",
              "arn:aws:secretsmanager:*:*:secret:/oracle/database/OASYSPTC/apex-passwords*",
            ]
          }
        ]
      }

      Ec2TrnBipPolicy = {
        description = "Permissions required for training Bip EC2s"
        statements = [
          {
            effect = "Allow"
            actions = [
              "secretsmanager:GetSecretValue",
            ]
            resources = [
              "arn:aws:secretsmanager:*:*:secret:/oracle/database/*TR/bip-*",
              "arn:aws:secretsmanager:*:*:secret:/oracle/database/TR*/bip-*",
              "arn:aws:secretsmanager:*:*:secret:/oracle/bip/trn/*",
            ]
          }
        ]
      }
      Ec2TrnWebPolicy = {
        description = "Permissions required for training Web EC2s"
        statements = [
          {
            effect = "Allow"
            actions = [
              "secretsmanager:GetSecretValue",
            ]
            resources = [
              "arn:aws:secretsmanager:*:*:secret:/oracle/database/TROASYS/apex-passwords*",
              "arn:aws:secretsmanager:*:*:secret:/oracle/database/OASYSTRN/apex-passwords*",
            ]
          }
        ]
      }
    }

    lbs = {
      public = merge(local.lbs.public, {
        access_logs_lifecycle_rule = [module.baseline_presets.s3_lifecycle_rules.general_purpose_one_year]

        listeners = merge(local.lbs.public.listeners, {
          https = merge(local.lbs.public.listeners.https, {
            certificate_names_or_arns = ["pd_oasys_cert"]

            alarm_target_group_names = [
              "pd-oasys-web-${local.web_live_side}-pb-http-8080",
            ]

            default_action = {
              type = "redirect"
              redirect = {
                host        = "oasys.service.justice.gov.uk"
                port        = "443"
                protocol    = "HTTPS"
                status_code = "HTTP_302"
              }
            }

            rules = {
              pd-web-http-8080 = {
                priority = 100
                actions = [{
                  type              = "forward"
                  target_group_name = "pd-oasys-web-${local.web_live_side}-pb-http-8080"
                }]
                conditions = [
                  {
                    host_header = {
                      values = [ # max of 5
                        "oasys.service.justice.gov.uk",
                        "bridge-oasys.az.justice.gov.uk",
                        "www.oasys.service.justice.gov.uk",
                      ]
                    }
                  }
                ]
              }
              pd-web-b-http-8080 = {
                priority = 101
                actions = [{
                  type              = "forward"
                  target_group_name = "pd-oasys-web-b-pb-http-8080"
                }]
                conditions = [
                  {
                    host_header = {
                      values = [ # max of 5
                        "b.oasys.service.justice.gov.uk",
                      ]
                    }
                  }
                ]
              }
              ptc-web-http-8080 = {
                priority = 200
                actions = [{
                  type              = "forward"
                  target_group_name = "ptc-oasys-web-a-pb-http-8080"
                }]
                conditions = [
                  {
                    host_header = {
                      values = [ # max of 5
                        "practice.bridge-oasys.az.justice.gov.uk",
                        "practice.oasys.service.justice.gov.uk",
                        "practice.a.oasys.service.justice.gov.uk",
                        "practice.b.oasys.service.justice.gov.uk",
                      ]
                    }
                  }
                ]
              }
              trn-web-http-8080 = {
                priority = 300
                actions = [{
                  type              = "forward"
                  target_group_name = "trn-oasys-web-a-pb-http-8080"
                }]
                conditions = [
                  {
                    host_header = {
                      values = [ # max of 5
                        "training.bridge-oasys.az.justice.gov.uk",
                        "training.oasys.service.justice.gov.uk",
                        "training.a.oasys.service.justice.gov.uk",
                        "training.b.oasys.service.justice.gov.uk",
                      ]
                    }
                  }
                ]
              }
            }
          })
        })
      })

      private = merge(local.lbs.private, {
        listeners = merge(local.lbs.private.listeners, {
          https = merge(local.lbs.private.listeners.https, {
            certificate_names_or_arns = ["pd_oasys_cert"]

            alarm_target_group_names = [
              "pd-oasys-web-${local.web_live_side}-pv-http-8080",
            ]

            default_action = {
              type = "redirect"
              redirect = {
                host        = "int.oasys.service.justice.gov.uk"
                port        = "443"
                protocol    = "HTTPS"
                status_code = "HTTP_302"
              }
            }

            rules = {
              pd-web-http-8080 = {
                priority = 100
                actions = [{
                  type              = "forward"
                  target_group_name = "pd-oasys-web-${local.web_live_side}-pv-http-8080"
                }]
                conditions = [
                  {
                    host_header = {
                      values = [ # max of 5
                        "int.oasys.service.justice.gov.uk",
                        "oasys-ukwest.oasys.az.justice.gov.uk",
                        # "oasys.az.justice.gov.uk",
                        "p-oasys.az.justice.gov.uk",
                      ]
                    }
                  }
                ]
              }
              pd-web-b-http-8080 = {
                priority = 101
                actions = [{
                  type              = "forward"
                  target_group_name = "pd-oasys-web-b-pv-http-8080"
                }]
                conditions = [
                  {
                    host_header = {
                      values = [ # max of 5
                        "b-int.oasys.service.justice.gov.uk",
                      ]
                    }
                  }
                ]
              }
              ptc-web-http-8080 = {
                priority = 200
                actions = [{
                  type              = "forward"
                  target_group_name = "ptc-oasys-web-a-pv-http-8080"
                }]
                conditions = [
                  {
                    host_header = {
                      values = [ # max of 5
                        "practice.int.oasys.service.justice.gov.uk",
                        "practice.oasys.az.justice.gov.uk",
                        "practice.p-oasys.az.justice.gov.uk",
                        # "practice-ukwest.oasys.az.justice.gov.uk",
                        "practice.a-int.oasys.service.justice.gov.uk",
                        "practice.b-int.oasys.service.justice.gov.uk",
                      ]
                    }
                  }
                ]
              }
              trn-web-http-8080 = {
                priority = 300
                actions = [{
                  type              = "forward"
                  target_group_name = "trn-oasys-web-a-pv-http-8080"
                }]
                conditions = [
                  {
                    host_header = {
                      values = [ # max of 5
                        "training.int.oasys.service.justice.gov.uk",
                        "training.oasys.az.justice.gov.uk",
                        "training.p-oasys.az.justice.gov.uk",
                        # "training-ukwest.oasys.az.justice.gov.uk",
                        "training.a-int.oasys.service.justice.gov.uk",
                        "training.b-int.oasys.service.justice.gov.uk",
                      ]
                    }
                  }
                ]
              }
            }
          })
        })
      })
    }

    route53_zones = {
      "hmpps-production.modernisation-platform.service.justice.gov.uk" = {
        records = [
          { name = "db.oasys", type = "CNAME", ttl = "3600", records = ["pd-oasys-db-a.oasys.hmpps-production.modernisation-platform.service.justice.gov.uk"] },
          { name = "db.trn.oasys", type = "CNAME", ttl = "3600", records = ["ptctrn-oasys-db-a.oasys.hmpps-production.modernisation-platform.service.justice.gov.uk"] },
          { name = "db.ptc.oasys", type = "CNAME", ttl = "3600", records = ["ptctrn-oasys-db-a.oasys.hmpps-production.modernisation-platform.service.justice.gov.uk"] },
          { name = "db.onr", type = "CNAME", ttl = "3600", records = ["pd-onr-db-a.oasys.hmpps-production.modernisation-platform.service.justice.gov.uk"] },
        ]
      }
      "oasys.service.justice.gov.uk" = {
        lb_alias_records = [
          { name = "", type = "A", lbs_map_key = "public" },
          { name = "www", type = "A", lbs_map_key = "public" },
          { name = "a", type = "A", lbs_map_key = "public" },
          { name = "b", type = "A", lbs_map_key = "public" },
          { name = "practice", type = "A", lbs_map_key = "public" },
          { name = "practice.a", type = "A", lbs_map_key = "public" },
          { name = "practice.b", type = "A", lbs_map_key = "public" },
          # { name = "ptc", type = "A", lbs_map_key = "public" },
          { name = "training", type = "A", lbs_map_key = "public" },
          { name = "training.a", type = "A", lbs_map_key = "public" },
          { name = "training.b", type = "A", lbs_map_key = "public" },
          # { name = "trn", type = "A", lbs_map_key = "public" },
          { name = "int", type = "A", lbs_map_key = "private" },
          { name = "a-int", type = "A", lbs_map_key = "private" },
          { name = "b-int", type = "A", lbs_map_key = "private" },
          { name = "practice.int", type = "A", lbs_map_key = "private" },
          { name = "practice.a-int", type = "A", lbs_map_key = "private" },
          { name = "practice.b-int", type = "A", lbs_map_key = "private" },
          # { name = "ptc-int", type = "A", lbs_map_key = "private" },
          { name = "training.int", type = "A", lbs_map_key = "private" },
          { name = "training.a-int", type = "A", lbs_map_key = "private" },
          { name = "training.b-int", type = "A", lbs_map_key = "private" },
          # { name = "trn-int", type = "A", lbs_map_key = "private" },
        ]
        records = [
          { name = "reporting", type = "NS", ttl = "86400", records = ["ns-1953.awsdns-52.co.uk", "ns-1415.awsdns-48.org", "ns-637.awsdns-15.net", "ns-454.awsdns-56.com"] },

          { name = "db.onr", type = "CNAME", ttl = "3600", records = ["pd-onr-db-a.oasys.hmpps-production.modernisation-platform.service.justice.gov.uk"] },
          { name = "db", type = "CNAME", ttl = "3600", records = ["pd-oasys-db-a.oasys.hmpps-production.modernisation-platform.service.justice.gov.uk"] },
          { name = "db-b", type = "CNAME", ttl = "3600", records = ["pd-oasys-db-b.oasys.hmpps-production.modernisation-platform.service.justice.gov.uk"] },

          { name = "db.pp.onr", type = "CNAME", ttl = "3600", records = ["pp-onr-db-a.oasys.hmpps-preproduction.modernisation-platform.service.justice.gov.uk"] },
          { name = "pp", type = "CNAME", ttl = "3600", records = ["public-lb-2107358561.eu-west-2.elb.amazonaws.com"] },
          { name = "db.pp", type = "CNAME", ttl = "3600", records = ["pp-oasys-db-a.oasys.hmpps-preproduction.modernisation-platform.service.justice.gov.uk"] },
          { name = "pp-a", type = "CNAME", ttl = "3600", records = ["public-lb-2107358561.eu-west-2.elb.amazonaws.com"] },
          { name = "pp-a-int", type = "CNAME", ttl = "3600", records = ["internal-private-lb-212442533.eu-west-2.elb.amazonaws.com"] },
          { name = "pp-int", type = "CNAME", ttl = "3600", records = ["internal-private-lb-212442533.eu-west-2.elb.amazonaws.com"] },

          { name = "t1", type = "CNAME", ttl = "3600", records = ["public-lb-1856376477.eu-west-2.elb.amazonaws.com"] },
          { name = "ords.t1", type = "CNAME", ttl = "3600", records = ["public-lb-1856376477.eu-west-2.elb.amazonaws.com"] },
          { name = "t1-int", type = "CNAME", ttl = "3600", records = ["internal-private-lb-1575012313.eu-west-2.elb.amazonaws.com"] },

          { name = "t2", type = "CNAME", ttl = "3600", records = ["public-lb-1856376477.eu-west-2.elb.amazonaws.com"] },
          { name = "ords.t2", type = "CNAME", ttl = "3600", records = ["public-lb-1856376477.eu-west-2.elb.amazonaws.com"] },
          { name = "t2-b", type = "CNAME", ttl = "3600", records = ["public-lb-1856376477.eu-west-2.elb.amazonaws.com"] },
          { name = "t2-b-int", type = "CNAME", ttl = "3600", records = ["internal-private-lb-1575012313.eu-west-2.elb.amazonaws.com"] },
          { name = "t2-int", type = "CNAME", ttl = "3600", records = ["internal-private-lb-1575012313.eu-west-2.elb.amazonaws.com"] },
          { name = "t2-c", type = "CNAME", ttl = "3600", records = ["public-lb-1856376477.eu-west-2.elb.amazonaws.com"] },
          { name = "t2-c-int", type = "CNAME", ttl = "3600", records = ["internal-private-lb-1575012313.eu-west-2.elb.amazonaws.com"] },

          { name = "_9f1b86e95d13d2cc7b9629f67d672c40", type = "CNAME", ttl = "86400", records = ["_7ea92a123c65795698dd19834dd71f61.fdbjvjdfdx.acm-validations.aws."] },
          { name = "_26aaae7b839510727c2dd323b483ea5d.pp", type = "CNAME", ttl = "86400", records = ["_72222d02a82256bb6d75c872bc7bc1aa.qxcwttcyyb.acm-validations.aws."] },
          { name = "_c3a661930d89914b2b25aac7d9947b3d.pp-a", type = "CNAME", ttl = "86400", records = ["_d57e6b487b03e7a7fd25e934671601cc.plkdfvcnsy.acm-validations.aws."] },
          { name = "_315500c40ef2d43ce87898e24be41f4e.pp-a-int", type = "CNAME", ttl = "86400", records = ["_be7c7a6b253419ba86f08cacabb28678.plkdfvcnsy.acm-validations.aws."] },
          { name = "_50d671c38e9c0d7692603c84d7ed066f.pp-b", type = "CNAME", ttl = "86400", records = ["_3aa768d4e3d8825ba1c8f2c2a154e7f4.plkdfvcnsy.acm-validations.aws."] },
          { name = "_a1ba1dd6ae3372f75a678b39e62364e0.pp-b-int", type = "CNAME", ttl = "86400", records = ["_eba205f55455280dbf39807cc4cd4a4f.plkdfvcnsy.acm-validations.aws."] },
          { name = "_b895eab0227a1d047f714060e0cd970f.pp-int", type = "CNAME", ttl = "86400", records = ["_9beca5f6af7ab9851e446fb506c15558.plkdfvcnsy.acm-validations.aws."] },
          { name = "_16d62060ae34f0c7e45cd3303d1369de.ords.t1", type = "CNAME", ttl = "86400", records = ["_3ace3d679497ac88b6b29516dc3e92ff.jsxlrrpjwm.acm-validations.aws."] },
          { name = "_93b16605cbf55e463d0ee7954b20c94d.t2", type = "CNAME", ttl = "86400", records = ["_51d8f8d87c9b9c07a1b1602bb68a1634.fcgjwsnkyp.acm-validations.aws."] },
          { name = "_594f919f3d6c4e462084ee328bdb3236.ords.t2", type = "CNAME", ttl = "86400", records = ["_734a121cabbafd1e18bb96a0f2de6ac6.jsxlrrpjwm.acm-validations.aws."] },
        ]
      }

      "hmpps-production.modernisation-platform.internal" = {
        vpc = { # this makes it a private hosted zone
          id = module.environment.vpc.id
        }
        records = [
          { name = "db.trn.oasys", type = "CNAME", ttl = "3600", records = ["ptctrn-oasys-db-a.oasys.hmpps-production.modernisation-platform.service.justice.gov.uk"] },
          { name = "db.ptc.oasys", type = "CNAME", ttl = "3600", records = ["ptctrn-oasys-db-a.oasys.hmpps-production.modernisation-platform.service.justice.gov.uk"] },
          { name = "db.oasys", type = "CNAME", ttl = "3600", records = ["pd-oasys-db-a.oasys.hmpps-production.modernisation-platform.internal"] },
          { name = "db.onr", type = "CNAME", ttl = "3600", records = ["pd-onr-db-a.oasys.hmpps-production.modernisation-platform.internal"] },
        ]
      }
    }

    secretsmanager_secrets = {
      "/oracle/bip/production" = local.secretsmanager_secrets.bip
      "/oracle/bip/trn"        = local.secretsmanager_secrets.bip

      "/oracle/database/PDOASYS" = local.secretsmanager_secrets.db_oasys
      "/oracle/database/PROASYS" = local.secretsmanager_secrets.db_oasys
      "/oracle/database/TROASYS" = local.secretsmanager_secrets.db_oasys
      "/oracle/database/DROASYS" = local.secretsmanager_secrets.db_oasys

      "/oracle/database/PDOASREP" = local.secretsmanager_secrets.db
      "/oracle/database/PDBIPINF" = local.secretsmanager_secrets.db_bip
      "/oracle/database/PDMISTRN" = local.secretsmanager_secrets.db
      "/oracle/database/PDONRSYS" = local.secretsmanager_secrets.db
      "/oracle/database/PDONRAUD" = local.secretsmanager_secrets.db
      "/oracle/database/PDONRBDS" = local.secretsmanager_secrets.db

      "/oracle/database/PDBOSYS" = local.secretsmanager_secrets.db_bip
      "/oracle/database/PDBOAUD" = local.secretsmanager_secrets.db_bip
      "/oracle/database/DRBOSYS" = local.secretsmanager_secrets.db_bip
      "/oracle/database/DRBOAUD" = local.secretsmanager_secrets.db_bip

      "/oracle/database/TRBIPINF" = local.secretsmanager_secrets.db_bip

      # for azure, remove when migrated to aws db
      "/oracle/database/OASPROD" = local.secretsmanager_secrets.db_oasys
    }

    # OASys is not supported out of hours.
    schedule_alarms_lambda = {
      alarm_patterns = [
        "*-cpu-iowait-high", # disable iowait alarm as planned out-of-hours work may trigger it
      ]
    }
  }

}
