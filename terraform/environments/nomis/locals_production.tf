# nomis-production environment settings
locals {

  # cloudwatch monitoring config
  production_cloudwatch_monitoring_options = {}

  # baseline presets config
  production_baseline_presets_options = {
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


  # baseline config
  production_config = {

    baseline_s3_buckets = {
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

    baseline_acm_certificates = {
      nomis_wildcard_cert = {
        # domain_name limited to 64 chars so use modernisation platform domain for this
        # and put the wildcard in the san
        domain_name = module.environment.domains.public.modernisation_platform
        subject_alternate_names = [
          "*.${module.environment.domains.public.application_environment}",
          "*.${local.environment}.nomis.service.justice.gov.uk",
          "*.${local.environment}.nomis.az.justice.gov.uk",
          "*.nomis.service.justice.gov.uk",
          "*.nomis.az.justice.gov.uk",
        ]
        external_validation_records_created = true
        cloudwatch_metric_alarms            = module.baseline_presets.cloudwatch_metric_alarms.acm
        tags = {
          description = "wildcard cert for nomis ${local.environment} domains"
        }
      }
    }

    baseline_iam_policies = {
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
        statements = [
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
        ]
      }
    }

    baseline_secretsmanager_secrets = {
      "/oracle/weblogic/prod"     = local.weblogic_secretsmanager_secrets
      "/oracle/database/PCNOM"    = local.database_nomis_secretsmanager_secrets
      "/oracle/database/PCNOMHA"  = local.database_secretsmanager_secrets
      "/oracle/database/PNDH"     = local.database_secretsmanager_secrets
      "/oracle/database/PTRDAT"   = local.database_secretsmanager_secrets
      "/oracle/database/PCNMAUD"  = local.database_secretsmanager_secrets
      "/oracle/database/PMIS"     = local.database_mis_secretsmanager_secrets
      "/oracle/database/DRCNOM"   = local.database_nomis_secretsmanager_secrets
      "/oracle/database/DRNDH"    = local.database_secretsmanager_secrets
      "/oracle/database/DRTRDAT"  = local.database_secretsmanager_secrets
      "/oracle/database/DRCNMAUD" = local.database_secretsmanager_secrets
      "/oracle/database/DRMIS"    = local.database_mis_secretsmanager_secrets
    }

    baseline_cloudwatch_log_groups = {
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

    baseline_ec2_autoscaling_groups = {
      # ACTIVE (blue deployment)
      prod-nomis-web-a = merge(local.weblogic_ec2, {
        autoscaling_group = merge(local.weblogic_ec2.autoscaling_group, {
          desired_capacity = 2
          max_size         = 2
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
          deployment           = "blue"
        })
      })

      # NOT-ACTIVE (green deployment)
      prod-nomis-web-b = merge(local.weblogic_ec2, {
        autoscaling_group = merge(local.weblogic_ec2.autoscaling_group, {
          desired_capacity = 0
          max_size         = 2
        })
        ## cloudwatch_metric_alarms = local.weblogic_cloudwatch_metric_alarms
        config = merge(local.weblogic_ec2.config, {
          ami_name = "nomis_rhel_6_10_weblogic_appserver_10_3_release_2023-03-15T17-18-22.178Z"

          instance_profile_policies = concat(local.weblogic_ec2.config.instance_profile_policies, [
            "Ec2ProdWeblogicPolicy",
          ])
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
        config = merge(local.jumpserver_ec2.config, {
          user_data_raw = base64encode(templatefile("./templates/jumpserver-user-data.yaml.tftpl", {
            ie_compatibility_mode_site_list = join(",", [
              "prod-nomis-web-a.production.nomis.service.justice.gov.uk/forms/frmservlet?config=tag",
              "prod-nomis-web-b.production.nomis.service.justice.gov.uk/forms/frmservlet?config=tag",
              "c.nomis.az.justice.gov.uk/forms/frmservlet?config=tag",
              "c.nomis.service.justice.gov.uk/forms/frmservlet?config=tag",
            ])
            ie_trusted_domains = join(",", [
              "*.nomis.hmpps-production.modernisation-platform.justice.gov.uk",
              "*.nomis.service.justice.gov.uk",
              "*.nomis.az.justice.gov.uk",
            ])
            desktop_shortcuts = join(",", [
              "Prod NOMIS|https://c.nomis.service.justice.gov.uk/forms/frmservlet?config=tag",
            ])
          }))
        })
      })
    }

    baseline_ec2_instances = {
      prod-nomis-db-1-b = merge(local.database_ec2, {
        cloudwatch_metric_alarms = merge(
          local.database_ec2_cloudwatch_metric_alarms.standard,
          local.database_ec2_cloudwatch_metric_alarms.db_connected, {
            high-memory-usage = merge(local.database_ec2_cloudwatch_metric_alarms.standard["high-memory-usage"], {
              threshold = "99" # Sandhya confirmed this is OK while in DR mode
            })
          }
        )
        config = merge(local.database_ec2.config, {
          ami_name          = "nomis_rhel_7_9_oracledb_11_2_release_2023-07-02T00-00-39.521Z"
          availability_zone = "${local.region}b"
          instance_profile_policies = concat(local.database_ec2.config.instance_profile_policies, [
            "Ec2ProdDatabasePolicy",
          ])
        })
        ebs_volumes = merge(local.database_ec2.ebs_volumes, {
          "/dev/sdb" = { label = "app", size = 100 }
          "/dev/sdc" = { label = "app", size = 500 }
        })
        ebs_volume_config = merge(local.database_ec2.ebs_volume_config, {
          data  = { total_size = 4000 }
          flash = { total_size = 1000 }
        })
        instance = merge(local.database_ec2.instance, {
          instance_type = "r6i.2xlarge"
        })
        tags = merge(local.database_ec2.tags, {
          nomis-environment = "prod"
          description       = "Disaster-Recovery/High-Availability production databases for CNOM and NDH"
          oracle-sids       = "DRCNOM DRNDH DRTRDAT"
        })
      })

      prod-nomis-db-2 = merge(local.database_ec2, {
        cloudwatch_metric_alarms = merge(
          local.database_ec2_cloudwatch_metric_alarms.standard,
          local.database_ec2_cloudwatch_metric_alarms.db_connected,
          local.database_ec2_cloudwatch_metric_alarms.connectivity_test,
          local.database_ec2_cloudwatch_metric_alarms.nomis_batch,
        )
        config = merge(local.database_ec2.config, {
          availability_zone = "${local.region}a"
          instance_profile_policies = concat(local.database_ec2.config.instance_profile_policies, [
            "Ec2ProdDatabasePolicy",
          ])
        })
        ebs_volumes = merge(local.database_ec2.ebs_volumes, {
          "/dev/sdb" = { label = "app", size = 100 }
          "/dev/sdc" = { label = "app", size = 3000, iops = 9000 }
        })
        ebs_volume_config = merge(local.database_ec2.ebs_volume_config, {
          data  = { total_size = 4000 }
          flash = { total_size = 1000 }
        })
        instance = merge(local.database_ec2.instance, {
          instance_type = "r6i.2xlarge"
        })
        tags = merge(local.database_ec2.tags, {
          nomis-environment  = "prod"
          description        = "Production NOMIS MIS and Audit database to replace Azure PDPDL00036 and PDPDL00038"
          oracle-sids        = "CNMAUD"
          connectivity-tests = "10.40.0.136:4903 10.40.129.79:22"
        })
      })

      prod-nomis-db-2-b = merge(local.database_ec2, {
        cloudwatch_metric_alarms = merge(
          local.database_ec2_cloudwatch_metric_alarms.standard,
          local.database_ec2_cloudwatch_metric_alarms.db_connected,
        )
        config = merge(local.database_ec2.config, {
          ami_name          = "nomis_rhel_7_9_oracledb_11_2_release_2023-07-02T00-00-39.521Z"
          availability_zone = "${local.region}b"
          instance_profile_policies = concat(local.database_ec2.config.instance_profile_policies, [
            "Ec2ProdDatabasePolicy",
          ])
        })
        ebs_volumes = merge(local.database_ec2.ebs_volumes, {
          "/dev/sdb" = { label = "app", size = 100 }
          "/dev/sdc" = { label = "app", size = 500 }
        })
        ebs_volume_config = merge(local.database_ec2.ebs_volume_config, {
          data  = { total_size = 4000 }
          flash = { total_size = 1000 }
        })
        instance = merge(local.database_ec2.instance, {
          instance_type = "r6i.2xlarge"
        })
        tags = merge(local.database_ec2.tags, {
          nomis-environment = "prod"
          description       = "Disaster-Recovery/High-Availability production databases for AUDIT/MIS"
          oracle-sids       = "DRMIS"
        })
      })

      prod-nomis-db-3 = merge(local.database_ec2, {
        cloudwatch_metric_alarms = merge(
          local.database_ec2_cloudwatch_metric_alarms.standard,
          local.database_ec2_cloudwatch_metric_alarms.db_connected,
        )
        config = merge(local.database_ec2.config, {
          availability_zone = "${local.region}a"
          instance_profile_policies = concat(local.database_ec2.config.instance_profile_policies, [
            "Ec2ProdDatabasePolicy",
          ])
        })
        ebs_volumes = merge(local.database_ec2.ebs_volumes, {
          "/dev/sdb" = { label = "app", size = 100 }
          "/dev/sdc" = { label = "app", size = 1000 }
        })
        ebs_volume_config = merge(local.database_ec2.ebs_volume_config, {
          data  = { total_size = 3000, iops = 3750, throughput = 750 }
          flash = { total_size = 500 }
        })
        instance = merge(local.database_ec2.instance, {
          instance_type = "r6i.4xlarge"
        })
        tags = merge(local.database_ec2.tags, {
          nomis-environment = "prod"
          description       = "Production NOMIS HA database to replace Azure PDPDL00062"
          oracle-sids       = "PCNOMHA"
        })
      })
    }

    baseline_lbs = {
      private = {
        internal_lb              = true
        enable_delete_protection = false
        force_destroy_bucket     = true
        idle_timeout             = 3600
        subnets                  = module.environment.subnets["private"].ids
        security_groups          = ["private-lb"]

        listeners = {
          http = local.weblogic_lb_listeners.http

          https = merge(
            local.weblogic_lb_listeners.https, {
              alarm_target_group_names = [
                "prod-nomis-web-a-http-7777",
                # "prod-nomis-web-b-http-7777",
              ]
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
                        "c.production.nomis.az.justice.gov.uk",
                        "c.nomis.service.justice.gov.uk",
                        "c.nomis.az.justice.gov.uk",
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
                      ]
                    }
                  }]
                }
              }
          })
        }
      }
    }

    baseline_route53_zones = {

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
          { name = "ndh", type = "NS", ttl = "86400", records = ["ns-1528.awsdns-63.org", "ns-973.awsdns-57.net", "ns-1867.awsdns-41.co.uk", "ns-427.awsdns-53.com"] },
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
          { name = "pnomis", type = "A", ttl = "300", records = ["10.40.3.132"] },
          { name = "pnomis-a", type = "A", ttl = "300", records = ["10.40.3.132"] },
          { name = "pnomis-b", type = "CNAME", ttl = "300", records = ["prod-nomis-db-1-b.nomis.hmpps-production.modernisation-platform.service.justice.gov.uk"] },
          { name = "pndh", type = "A", ttl = "300", records = ["10.40.3.135"] },
          { name = "pndh-a", type = "A", ttl = "300", records = ["10.40.3.135"] },
          { name = "pndh-b", type = "CNAME", ttl = "300", records = ["prod-nomis-db-1-b.nomis.hmpps-production.modernisation-platform.service.justice.gov.uk"] },
          { name = "por", type = "CNAME", ttl = "300", records = ["prod-nomis-db-3.nomis.hmpps-production.modernisation-platform.service.justice.gov.uk"] },
          { name = "por-a", type = "CNAME", ttl = "300", records = ["prod-nomis-db-3.nomis.hmpps-production.modernisation-platform.service.justice.gov.uk"] },
          { name = "por-b", type = "CNAME", ttl = "300", records = ["prod-nomis-db-1-b.nomis.hmpps-production.modernisation-platform.service.justice.gov.uk"] },
          { name = "ptrdat", type = "A", ttl = "300", records = ["10.40.3.135"] },
          { name = "ptrdat-a", type = "A", ttl = "300", records = ["10.40.3.135"] },
          { name = "ptrdat-b", type = "CNAME", ttl = "300", records = ["prod-nomis-db-1-b.nomis.hmpps-production.modernisation-platform.service.justice.gov.uk"] },
          { name = "paudit", type = "CNAME", ttl = "300", records = ["prod-nomis-db-2.nomis.hmpps-production.modernisation-platform.service.justice.gov.uk"] },
          { name = "paudit-a", type = "CNAME", ttl = "300", records = ["prod-nomis-db-2.nomis.hmpps-production.modernisation-platform.service.justice.gov.uk"] },
          { name = "paudit-b", type = "CNAME", ttl = "300", records = ["prod-nomis-db-2-b.nomis.hmpps-production.modernisation-platform.service.justice.gov.uk"] },
          { name = "pmis", type = "A", ttl = "300", records = ["10.40.3.133"] },
          { name = "pmis-a", type = "A", ttl = "300", records = ["10.40.3.133"] },
          { name = "pmis-b", type = "CNAME", ttl = "300", records = ["prod-nomis-db-2-b.nomis.hmpps-production.modernisation-platform.service.justice.gov.uk"] },
          { name = "pnomisapiro", type = "CNAME", ttl = "300", records = ["prod-nomis-db-3.nomis.hmpps-production.modernisation-platform.service.justice.gov.uk"] },
          { name = "pnomisapiro-a", type = "CNAME", ttl = "300", records = ["prod-nomis-db-3.nomis.hmpps-production.modernisation-platform.service.justice.gov.uk"] },
          { name = "pnomisapiro-b", type = "CNAME", ttl = "300", records = ["prod-nomis-db-1-b.nomis.hmpps-production.modernisation-platform.service.justice.gov.uk"] },
        ]
        lb_alias_records = [
          { name = "prod-nomis-web-a", type = "A", lbs_map_key = "private" },
          { name = "prod-nomis-web-b", type = "A", lbs_map_key = "private" },
          { name = "c", type = "A", lbs_map_key = "private" },
        ]
      }
    }
  }
}
