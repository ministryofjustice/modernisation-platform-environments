# nomis-production environment settings
locals {

  lb_maintenance_message_production = {
    maintenance_title   = "Prison-NOMIS Maintenance Window"
    maintenance_message = "Prison-NOMIS is currently unavailable due to planned maintenance. Please try again later"
  }

  baseline_presets_production = {
    options = {
      cloudwatch_dashboard_default_widget_groups = [
        "lb",
        "ec2",
        "ec2_linux",
        "ec2_autoscaling_group_linux",
        "ec2_instance_linux",
        "ec2_instance_oracle_db_with_backup",
        "ec2_instance_textfile_monitoring_with_connectivity_test",
      ]
      sns_topics = {
        pagerduty_integrations = {
          dso_pagerduty               = "nomis_alarms"
          dba_pagerduty               = "hmpps_shef_dba_low_priority"
          dba_high_priority_pagerduty = "hmpps_shef_dba_high_priority"
        }
      }
      route53_resolver_rules = {
        outbound-data-and-private-subnets = ["azure-fixngo-domain", "infra-int-domain"]
      }
    }
  }

  # please keep resources in alphabetical order
  baseline_production = {

    acm_certificates = {
      nomis_wildcard_cert = {
        # domain_name limited to 64 chars so use modernisation platform domain for this
        # and put the wildcard in the san
        domain_name = "modernisation-platform.service.justice.gov.uk"
        subject_alternate_names = [
          "*.nomis.hmpps-production.modernisation-platform.service.justice.gov.uk",
          "*.production.nomis.service.justice.gov.uk",
          "*.production.nomis.az.justice.gov.uk",
          "*.nomis.service.justice.gov.uk",
          "*.nomis.az.justice.gov.uk",
        ]
        external_validation_records_created = true
        cloudwatch_metric_alarms            = module.baseline_presets.cloudwatch_metric_alarms.acm
        tags = {
          description = "wildcard cert for nomis production domains"
        }
      }
    }

    cloudwatch_log_groups = {
      session-manager-logs = {
        retention_in_days = 400
      }
      cwagent-var-log-messages = {
        retention_in_days = 90
      }
      cwagent-var-log-secure = {
        retention_in_days = 400
      }
      cwagent-windows-system = {
        retention_in_days = 90
      }
      cwagent-nomis-autologoff = {
        retention_in_days = 400
      }
      cwagent-weblogic-logs = {
        retention_in_days = 90
      }
    }

    ec2_autoscaling_groups = {
      # NOT-ACTIVE (blue deployment)
      prod-nomis-web-a = merge(local.weblogic_ec2, {
        autoscaling_group = merge(local.weblogic_ec2.autoscaling_group, {
          desired_capacity = 0
          max_size         = 0
        })
        # cloudwatch_metric_alarms = local.weblogic_cloudwatch_metric_alarms
        config = merge(local.weblogic_ec2.config, {
          ami_name = "nomis_rhel_6_10_weblogic_appserver_10_3_release_2023-03-15T17-18-22.178Z"
          instance_profile_policies = concat(local.weblogic_ec2.config.instance_profile_policies, [
            "Ec2ProdWeblogicPolicy",
          ])
        })
        instance = merge(local.weblogic_ec2.instance, {
          instance_type = "r4.2xlarge"
        })
        user_data_cloud_init = merge(local.weblogic_ec2.user_data_cloud_init, {
          args = merge(local.weblogic_ec2.user_data_cloud_init.args, {
            branch = "main"
          })
        })
        tags = merge(local.weblogic_ec2.tags, {
          nomis-environment    = "prod"
          oracle-db-hostname-a = "pnomis-a.production.nomis.service.justice.gov.uk"
          oracle-db-hostname-b = "pnomis-b.production.nomis.service.justice.gov.uk"
          oracle-db-name       = "PCNOM"
          deployment           = "blue"
        })
      })

      # ACTIVE (green deployment)
      prod-nomis-web-b = merge(local.weblogic_ec2, {
        autoscaling_group = merge(module.baseline_presets.ec2_autoscaling_group.default_with_ready_hook_and_warm_pool, {
          desired_capacity = 8
          max_size         = 8
        })
        cloudwatch_metric_alarms = local.weblogic_cloudwatch_metric_alarms
        config = merge(local.weblogic_ec2.config, {
          ami_name = "nomis_rhel_6_10_weblogic_appserver_10_3_release_2023-03-15T17-18-22.178Z"
          instance_profile_policies = concat(local.weblogic_ec2.config.instance_profile_policies, [
            "Ec2ProdWeblogicPolicy",
          ])
        })
        instance = merge(local.weblogic_ec2.instance, {
          instance_type = "r4.2xlarge"
        })
        user_data_cloud_init = merge(local.weblogic_ec2.user_data_cloud_init, {
          args = merge(local.weblogic_ec2.user_data_cloud_init.args, {
            branch = "main"
          })
        })
        tags = merge(local.weblogic_ec2.tags, {
          nomis-environment    = "prod"
          oracle-db-hostname-a = "pnomis-a.production.nomis.service.justice.gov.uk"
          oracle-db-hostname-b = "pnomis-b.production.nomis.service.justice.gov.uk"
          oracle-db-name       = "PCNOM"
          deployment           = "green"
        })
      })

      prod-nomis-client-a = merge(local.jumpserver_ec2, {
        tags = merge(local.jumpserver_ec2.tags, {
          domain-name = "azure.hmpp.root"
        })
      })
    }

    ec2_instances = {
      prod-nomis-xtag-a = merge(local.xtag_ec2, {
        cloudwatch_metric_alarms = local.xtag_cloudwatch_metric_alarms
        config = merge(local.xtag_ec2.config, {
          ami_name          = "nomis_rhel_7_9_weblogic_xtag_10_3_release_2023-12-21T17-09-11.541Z"
          availability_zone = "eu-west-2a"
          instance_profile_policies = concat(local.xtag_ec2.config.instance_profile_policies, [
            "Ec2ProdWeblogicPolicy",
          ])
        })
        user_data_cloud_init = merge(local.xtag_ec2.user_data_cloud_init, {
          args = merge(local.xtag_ec2.user_data_cloud_init.args, {
            branch = "main"
          })
        })
        tags = merge(local.xtag_ec2.tags, {
          nomis-environment    = "prod"
          oracle-db-hostname-a = "pnomis-a.production.nomis.service.justice.gov.uk"
          oracle-db-hostname-b = "pnomis-b.production.nomis.service.justice.gov.uk"
          oracle-db-name       = "PCNOM"
          ndh-ems-hostname     = "pd-ems.ndh.nomis.service.justice.gov.uk"
        })
      })

      prod-nomis-db-1-a = merge(local.database_ec2, {
        cloudwatch_metric_alarms = merge(
          local.database_ec2_cloudwatch_metric_alarms.standard,
          local.database_ec2_cloudwatch_metric_alarms.db_connected,
          local.database_ec2_cloudwatch_metric_alarms.db_backup,
          local.database_ec2_cloudwatch_metric_alarms.nomis_batch,
        )
        config = merge(local.database_ec2.config, {
          ami_name          = "nomis_rhel_7_9_oracledb_11_2_release_2023-07-02T00-00-39.521Z"
          availability_zone = "eu-west-2a"
          instance_profile_policies = concat(local.database_ec2.config.instance_profile_policies, [
            "Ec2ProdDatabasePolicy",
          ])
        })
        ebs_volumes = merge(local.database_ec2.ebs_volumes, {
          "/dev/sdb" = { label = "app", size = 100 }  # /u01
          "/dev/sdc" = { label = "app", size = 1000 } # /u02
        })
        ebs_volume_config = merge(local.database_ec2.ebs_volume_config, {
          data  = { total_size = 4000, iops = 12000, throughput = 750 }
          flash = { total_size = 1000, iops = 5000, throughput = 500 }
        })
        instance = merge(local.database_ec2.instance, {
          disable_api_termination = true
          instance_type           = "r6i.4xlarge"
        })
        tags = merge(local.database_ec2.tags, {
          nomis-environment = "prod"
          description       = "Production databases for CNOM and NDH"
          oracle-sids       = "PDCNOM PDNDH PDTRDAT"
        })
      })

      prod-nomis-db-1-b = merge(local.database_ec2, {
        cloudwatch_metric_alarms = merge(
          local.database_ec2_cloudwatch_metric_alarms.standard,
          local.database_ec2_cloudwatch_metric_alarms.db_connected,
        )
        config = merge(local.database_ec2.config, {
          ami_name          = "nomis_rhel_7_9_oracledb_11_2_release_2023-07-02T00-00-39.521Z"
          availability_zone = "eu-west-2b"
          instance_profile_policies = concat(local.database_ec2.config.instance_profile_policies, [
            "Ec2ProdDatabasePolicy",
          ])
        })
        ebs_volumes = merge(local.database_ec2.ebs_volumes, {
          "/dev/sdb" = { label = "app", size = 100 }
          "/dev/sdc" = { label = "app", size = 500 }
        })
        ebs_volume_config = merge(local.database_ec2.ebs_volume_config, {
          data  = { total_size = 4000, iops = 12000, throughput = 750 }
          flash = { total_size = 1000, iops = 5000, throughput = 500 }
        })
        instance = merge(local.database_ec2.instance, {
          disable_api_termination = true
          instance_type           = "r6i.4xlarge"
        })
        tags = merge(local.database_ec2.tags, {
          nomis-environment = "prod"
          description       = "Disaster-Recovery/High-Availability production databases for CNOM and NDH"
          oracle-sids       = "DRCNOM DRNDH DRTRDAT"
        })
      })

      prod-nomis-db-2-a = merge(local.database_ec2, {
        cloudwatch_metric_alarms = merge(
          local.database_ec2_cloudwatch_metric_alarms.standard,
          local.database_ec2_cloudwatch_metric_alarms.db_connected,
          local.database_ec2_cloudwatch_metric_alarms.db_backup,
          local.database_ec2_cloudwatch_metric_alarms.misload,
        )
        config = merge(local.database_ec2.config, {
          ami_name          = "nomis_rhel_7_9_oracledb_11_2_release_2023-07-02T00-00-39.521Z"
          availability_zone = "eu-west-2a"
          instance_profile_policies = concat(local.database_ec2.config.instance_profile_policies, [
            "Ec2ProdDatabasePolicy",
          ])
        })
        ebs_volumes = merge(local.database_ec2.ebs_volumes, {
          "/dev/sdb" = { label = "app", size = 100 }  # /u01
          "/dev/sdc" = { label = "app", size = 1000 } # /u02
        })
        ebs_volume_config = merge(local.database_ec2.ebs_volume_config, {
          data  = { total_size = 6000, iops = 12000, throughput = 750 }
          flash = { total_size = 1000, iops = 5000, throughput = 500 }
        })
        instance = merge(local.database_ec2.instance, {
          disable_api_termination = true
          instance_type           = "r6i.4xlarge"
        })
        tags = merge(local.database_ec2.tags, {
          nomis-environment = "prod"
          description       = "Production databases for AUDIT/MIS"
          oracle-sids       = "PDCNMAUD PDMIS"
          misload-dbname    = "PDMIS"
        })
      })

      prod-nomis-db-2-b = merge(local.database_ec2, {
        cloudwatch_metric_alarms = merge(
          local.database_ec2_cloudwatch_metric_alarms.standard,
          local.database_ec2_cloudwatch_metric_alarms.db_connected,
          local.database_ec2_cloudwatch_metric_alarms.connectivity_test,
        )
        config = merge(local.database_ec2.config, {
          ami_name          = "nomis_rhel_7_9_oracledb_11_2_release_2023-07-02T00-00-39.521Z"
          availability_zone = "eu-west-2b"
          instance_profile_policies = concat(local.database_ec2.config.instance_profile_policies, [
            "Ec2ProdDatabasePolicy",
          ])
        })
        ebs_volumes = merge(local.database_ec2.ebs_volumes, {
          "/dev/sdb" = { label = "app", size = 100 }
          "/dev/sdc" = { label = "app", size = 500 }
        })
        ebs_volume_config = merge(local.database_ec2.ebs_volume_config, {
          data  = { total_size = 6000, iops = 12000, throughput = 750 }
          flash = { total_size = 1000, iops = 5000, throughput = 500 }
        })
        instance = merge(local.database_ec2.instance, {
          disable_api_termination = true
          instance_type           = "r6i.4xlarge"
        })
        tags = merge(local.database_ec2.tags, {
          nomis-environment  = "prod"
          description        = "Disaster-Recovery/High-Availability production databases for AUDIT/MIS"
          oracle-sids        = "DRMIS DRCNMAUD"
          misload-dbname     = "DRMIS"
          connectivity-tests = "10.40.0.133:53 10.40.129.79:22"
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
              "ssm:GetParameter",
            ]
            resources = [
              "arn:aws:ssm:*:*:parameter/azure/*",
            ]
          },
          {
            effect = "Allow"
            actions = [
              "secretsmanager:GetSecretValue",
              "secretsmanager:PutSecretValue",
            ]
            resources = [
              "arn:aws:secretsmanager:*:*:secret:/oracle/database/*P/*",
              "arn:aws:secretsmanager:*:*:secret:/oracle/database/P*/*",
              "arn:aws:secretsmanager:*:*:secret:/oracle/database/*DR/*",
              "arn:aws:secretsmanager:*:*:secret:/oracle/database/DR*/*",
            ]
          }
        ]
      }
      Ec2ProdWeblogicPolicy = {
        description = "Permissions required for prod Weblogic EC2s"
        statements = concat(local.weblogic_iam_policy_statements, [
          {
            effect = "Allow"
            actions = [
              "secretsmanager:GetSecretValue",
              "secretsmanager:PutSecretValue",
            ]
            resources = [
              "arn:aws:secretsmanager:*:*:secret:/oracle/weblogic/prod/*",
              "arn:aws:secretsmanager:*:*:secret:/oracle/database/P*/weblogic-*",
              "arn:aws:secretsmanager:*:*:secret:/oracle/database/*P/weblogic-*",
              "arn:aws:secretsmanager:*:*:secret:/oracle/database/DR*/weblogic-*",
              "arn:aws:secretsmanager:*:*:secret:/oracle/database/*DR/weblogic-*",
            ]
          }
        ])
      }
    }

    lbs = {
      private = {
        internal_lb              = true
        enable_delete_protection = false
        force_destroy_bucket     = true
        idle_timeout             = 3600
        subnets                  = module.environment.subnets["private"].ids
        security_groups          = ["private-lb"]

        listeners = {
          http = local.weblogic_lb_listeners.http

          https = merge(local.weblogic_lb_listeners.https, {
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
                      "prod-nomis-web-a.production.nomis.az.justice.gov.uk",
                      "prod-nomis-web-a.production.nomis.service.justice.gov.uk",
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
                      "prod-nomis-web-b.production.nomis.az.justice.gov.uk",
                      "prod-nomis-web-b.production.nomis.service.justice.gov.uk",
                      "c.production.nomis.az.justice.gov.uk",
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
        }
      }
    }

    route53_zones = {

      "hmpps-production.modernisation-platform.internal" = {
      }
      "nomis.service.justice.gov.uk" = {
        # NOTE this top level zone is currently hosted in Azure but
        # will be moved here at some point
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
      "production.nomis.az.justice.gov.uk" = {
        lb_alias_records = [
          { name = "prod-nomis-web-a", type = "A", lbs_map_key = "private" },
          { name = "prod-nomis-web-b", type = "A", lbs_map_key = "private" },
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
          { name = "por-b", type = "CNAME", ttl = "300", records = ["prod-nomis-db-1-b.nomis.hmpps-production.modernisation-platform.service.justice.gov.uk"] },
          { name = "ptrdat", type = "CNAME", ttl = "300", records = ["prod-nomis-db-1-a.nomis.hmpps-production.modernisation-platform.service.justice.gov.uk"] },
          { name = "ptrdat-a", type = "CNAME", ttl = "300", records = ["prod-nomis-db-1-a.nomis.hmpps-production.modernisation-platform.service.justice.gov.uk"] },
          { name = "ptrdat-b", type = "CNAME", ttl = "300", records = ["prod-nomis-db-1-b.nomis.hmpps-production.modernisation-platform.service.justice.gov.uk"] },
          { name = "paudit", type = "CNAME", ttl = "300", records = ["prod-nomis-db-2-a.nomis.hmpps-production.modernisation-platform.service.justice.gov.uk"] },
          { name = "paudit-a", type = "CNAME", ttl = "300", records = ["prod-nomis-db-2-a.nomis.hmpps-production.modernisation-platform.service.justice.gov.uk"] },
          { name = "paudit-b", type = "CNAME", ttl = "300", records = ["prod-nomis-db-2-b.nomis.hmpps-production.modernisation-platform.service.justice.gov.uk"] },
          { name = "pmis", type = "CNAME", ttl = "300", records = ["prod-nomis-db-2-a.nomis.hmpps-production.modernisation-platform.service.justice.gov.uk"] },
          { name = "pmis-a", type = "CNAME", ttl = "300", records = ["prod-nomis-db-2-a.nomis.hmpps-production.modernisation-platform.service.justice.gov.uk"] },
          { name = "pmis-b", type = "CNAME", ttl = "300", records = ["prod-nomis-db-2-b.nomis.hmpps-production.modernisation-platform.service.justice.gov.uk"] },
          { name = "pnomisapiro", type = "CNAME", ttl = "300", records = ["prod-nomis-db-1-b.nomis.hmpps-production.modernisation-platform.service.justice.gov.uk"] },
          { name = "pnomisapiro-a", type = "CNAME", ttl = "300", records = ["prod-nomis-db-1-b.nomis.hmpps-production.modernisation-platform.service.justice.gov.uk"] },
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
        custom_kms_key = module.environment.kms_keys["general"].arn
        bucket_policy_v2 = [
          module.baseline_presets.s3_bucket_policies.ProdPreprodEnvironmentsReadOnlyAccessBucketPolicy,
        ]
        iam_policies = module.baseline_presets.s3_iam_policies
        lifecycle_rule = [
          module.baseline_presets.s3_lifecycle_rules.ninety_day_standard_ia_ten_year_expiry
        ]
      }
      nomis-db-backup-bucket = {
        custom_kms_key = module.environment.kms_keys["general"].arn
        bucket_policy_v2 = [
          module.baseline_presets.s3_bucket_policies.ProdPreprodEnvironmentsReadOnlyAccessBucketPolicy,
        ]
        iam_policies = module.baseline_presets.s3_iam_policies
      }
    }

    secretsmanager_secrets = {
      "/oracle/weblogic/prod"  = local.weblogic_secretsmanager_secrets
      "/oracle/database/PCNOM" = local.database_weblogic_secretsmanager_secrets # weblogic oracle-db-name set to PCNOM
      # PROD ACTIVE
      "/oracle/database/PDCNOM"   = local.database_secretsmanager_secrets
      "/oracle/database/PDNDH"    = local.database_secretsmanager_secrets
      "/oracle/database/PDTRDAT"  = local.database_secretsmanager_secrets
      "/oracle/database/PDCNMAUD" = local.database_secretsmanager_secrets
      "/oracle/database/PDMIS"    = local.database_mis_secretsmanager_secrets
      # PROD STANDBY
      "/oracle/database/DRCNOM"   = local.database_secretsmanager_secrets
      "/oracle/database/DRNDH"    = local.database_secretsmanager_secrets
      "/oracle/database/DRTRDAT"  = local.database_secretsmanager_secrets
      "/oracle/database/DRCNMAUD" = local.database_secretsmanager_secrets
      "/oracle/database/DRMIS"    = local.database_mis_secretsmanager_secrets
    }
  }
}
