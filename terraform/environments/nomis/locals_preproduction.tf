locals {

  lb_maintenance_message_preproduction = {
    maintenance_title   = "Prison-NOMIS Maintenance Window"
    maintenance_message = "Prison-NOMIS is currently unavailable due to planned maintenance. Please try again later"
  }

  baseline_presets_preproduction = {
    options = {
      sns_topics = {
        pagerduty_integrations = {
          dso_pagerduty               = "nomis_alarms"
          dba_pagerduty               = "hmpps_shef_dba_low_priority"
          dba_high_priority_pagerduty = "hmpps_shef_dba_low_priority"
        }
      }
      route53_resolver_rules = {
        outbound-data-and-private-subnets = ["azure-fixngo-domain", "infra-int-domain"]
      }
    }
  }

  # please keep resources in alphabetical order
  baseline_preproduction = {

    acm_certificates = {
      nomis_wildcard_cert = {
        # domain_name limited to 64 chars so use modernisation platform domain for this
        # and put the wildcard in the san
        domain_name = "modernisation-platform.service.justice.gov.uk"
        subject_alternate_names = [
          "*.nomis.hmpps-preproduction.modernisation-platform.service.justice.gov.uk",
          "*.preproduction.nomis.service.justice.gov.uk",
          "*.preproduction.nomis.az.justice.gov.uk",
          "*.pp-nomis.az.justice.gov.uk",
          "*.lsast-nomis.az.justice.gov.uk",
        ]
        external_validation_records_created = true
        cloudwatch_metric_alarms            = module.baseline_presets.cloudwatch_metric_alarms.acm
        tags = {
          description = "wildcard cert for nomis preproduction domains"
        }
      }
    }

    ec2_autoscaling_groups = {
      # ACTIVE (blue deployment)
      preprod-nomis-web-a = merge(local.weblogic_ec2, {
        autoscaling_group = merge(local.weblogic_ec2.autoscaling_group, {
          desired_capacity = 2
          max_size         = 2
        })
        cloudwatch_metric_alarms = local.weblogic_cloudwatch_metric_alarms
        config = merge(local.weblogic_ec2.config, {
          ami_name = "nomis_rhel_6_10_weblogic_appserver_10_3_release_2023-03-15T17-18-22.178Z"
          instance_profile_policies = concat(local.weblogic_ec2.config.instance_profile_policies, [
            "Ec2PreprodWeblogicPolicy",
          ])
        })
        user_data_cloud_init = merge(local.weblogic_ec2.user_data_cloud_init, {
          args = merge(local.weblogic_ec2.user_data_cloud_init.args, {
            branch = "main"
          })
        })
        tags = merge(local.weblogic_ec2.tags, {
          nomis-environment    = "preprod"
          oracle-db-hostname-a = "ppnomis-a.preproduction.nomis.service.justice.gov.uk"
          oracle-db-hostname-b = "ppnomis-b.preproduction.nomis.service.justice.gov.uk"
          oracle-db-name       = "PPCNOM"
          deployment           = "blue"
        })
      })

      # NOT-ACTIVE (green deployment)
      preprod-nomis-web-b = merge(local.weblogic_ec2, {
        # autoscaling_group = merge(module.baseline_presets.ec2_autoscaling_group.default_with_ready_hook_and_warm_pool, {
        autoscaling_group = merge(local.weblogic_ec2.autoscaling_group, {
          desired_capacity = 0
        })
        # autoscaling_schedules = {
        #   scale_up   = { recurrence = "0 7 * * Mon-Fri" }
        #   scale_down = { recurrence = "0 18 * * Mon-Fri", desired_capacity = 1 }
        # }
        # cloudwatch_metric_alarms = local.weblogic_cloudwatch_metric_alarms
        config = merge(local.weblogic_ec2.config, {
          ami_name = "nomis_rhel_6_10_weblogic_appserver_10_3_release_2023-03-15T17-18-22.178Z"
          instance_profile_policies = concat(local.weblogic_ec2.config.instance_profile_policies, [
            "Ec2PreprodWeblogicPolicy",
          ])
        })
        user_data_cloud_init = merge(local.weblogic_ec2.user_data_cloud_init, {
          args = merge(local.weblogic_ec2.user_data_cloud_init.args, {
            branch = "main"
          })
        })
        tags = merge(local.weblogic_ec2.tags, {
          nomis-environment    = "preprod"
          oracle-db-hostname-a = "ppnomis-a.preproduction.nomis.service.justice.gov.uk"
          oracle-db-hostname-b = "ppnomis-b.preproduction.nomis.service.justice.gov.uk"
          oracle-db-name       = "PPCNOM"
          deployment           = "green"
        })
      })

      preprod-nomis-client-a = local.jumpserver_ec2
    }

    ec2_instances = {
      lsast-nomis-db-1-a = merge(local.database_ec2, {
        #cloudwatch_metric_alarms = merge(
        #  local.database_ec2_cloudwatch_metric_alarms.standard,
        #  local.database_ec2_cloudwatch_metric_alarms.db_connected,
        #)
        config = merge(local.database_ec2.config, {
          ami_name          = "nomis_rhel_7_9_oracledb_11_2_release_2023-07-02T00-00-39.521Z"
          availability_zone = "eu-west-2a"
          instance_profile_policies = concat(local.database_ec2.config.instance_profile_policies, [
            "Ec2LsastDatabasePolicy",
          ])
        })
        ebs_volumes = merge(local.database_ec2.ebs_volumes, {
          "/dev/sdb" = { label = "app", size = 100 }
          "/dev/sdc" = { label = "app", size = 500 }
        })
        ebs_volume_config = merge(local.database_ec2.ebs_volume_config, {
          data  = { total_size = 5000 }
          flash = { total_size = 500 }
        })
        instance = merge(local.database_ec2.instance, {
          disable_api_termination = true
          instance_type           = "r6i.2xlarge"
        })
        tags = merge(local.database_ec2.tags, {
          nomis-environment = "lsast"
          description       = "lsast database for CNOM and MIS"
          oracle-sids       = ""
        })
      })

      preprod-nomis-db-1-a = merge(local.database_ec2, {
        cloudwatch_metric_alarms = merge(
          local.database_ec2_cloudwatch_metric_alarms.standard,
          local.database_ec2_cloudwatch_metric_alarms.db_connected,
        )
        config = merge(local.database_ec2.config, {
          ami_name          = "nomis_rhel_7_9_oracledb_11_2_release_2023-07-02T00-00-39.521Z"
          availability_zone = "eu-west-2a"
          instance_profile_policies = concat(local.database_ec2.config.instance_profile_policies, [
            "Ec2PreprodDatabasePolicy",
          ])
        })
        ebs_volumes = merge(local.database_ec2.ebs_volumes, {
          "/dev/sdb" = { label = "app", size = 100 }
          "/dev/sdc" = { label = "app", size = 1000 }
        })
        ebs_volume_config = merge(local.database_ec2.ebs_volume_config, {
          data  = { total_size = 4000 }
          flash = { total_size = 1000 }
        })
        instance = merge(local.database_ec2.instance, {
          disable_api_termination = true
          instance_type           = "r6i.2xlarge"
        })
        tags = merge(local.database_ec2.tags, {
          nomis-environment = "preprod"
          description       = "pre-production database for CNOMPP"
          oracle-sids       = "PPCNOM PPNDH PPTRDAT"
        })
      })

      preprod-nomis-db-1-b = merge(local.database_ec2, {
        cloudwatch_metric_alarms = merge(
          local.database_ec2_cloudwatch_metric_alarms.standard,
        )
        config = merge(local.database_ec2.config, {
          ami_name          = "nomis_rhel_7_9_oracledb_11_2_release_2023-07-02T00-00-39.521Z"
          availability_zone = "eu-west-2b"
          instance_profile_policies = concat(local.database_ec2.config.instance_profile_policies, [
            "Ec2PreprodDatabasePolicy",
          ])
        })
        ebs_volumes = merge(local.database_ec2.ebs_volumes, {
          "/dev/sdb" = { label = "app", size = 100 }
          "/dev/sdc" = { label = "app", size = 500 }
        })
        ebs_volume_config = merge(local.database_ec2.ebs_volume_config, {
          data  = { total_size = 3000 }
          flash = { total_size = 1000 }
        })
        instance = merge(local.database_ec2.instance, {
          disable_api_termination = true
          instance_type           = "r6i.2xlarge"
        })
        tags = merge(local.database_ec2.tags, {
          nomis-environment = "preprod"
          description       = "Disaster-Recovery/High-Availability pre-production database for CNOMPP"
          oracle-sids       = "PPCNOMHA"
        })
      })

      preprod-nomis-db-2-a = merge(local.database_ec2, {
        cloudwatch_metric_alarms = merge(
          local.database_ec2_cloudwatch_metric_alarms.standard,
          local.database_ec2_cloudwatch_metric_alarms.db_connected,
          local.database_ec2_cloudwatch_metric_alarms.misload,
        )
        config = merge(local.database_ec2.config, {
          ami_name          = "nomis_rhel_7_9_oracledb_11_2_release_2023-07-02T00-00-39.521Z"
          availability_zone = "eu-west-2a"
          instance_profile_policies = concat(local.database_ec2.config.instance_profile_policies, [
            "Ec2PreprodDatabasePolicy",
          ])
        })
        ebs_volumes = merge(local.database_ec2.ebs_volumes, {
          "/dev/sdb" = { label = "app", size = 100 }
          "/dev/sdc" = { label = "app", size = 512 }
        })
        ebs_volume_config = merge(local.database_ec2.ebs_volume_config, {
          data  = { total_size = 4000 }
          flash = { total_size = 1000 }
        })
        instance = merge(local.database_ec2.instance, {
          disable_api_termination = true
          instance_type           = "r6i.2xlarge"
        })
        tags = merge(local.database_ec2.tags, {
          nomis-environment = "preprod"
          description       = "PreProduction NOMIS MIS and Audit database"
          oracle-sids       = "PPMIS PPCNMAUD"
          misload-dbname    = "PPMIS"
        })
      })

      preprod-nomis-xtag-a = merge(local.xtag_ec2, {
        cloudwatch_metric_alarms = local.xtag_cloudwatch_metric_alarms
        config = merge(local.xtag_ec2.config, {
          ami_name          = "nomis_rhel_7_9_weblogic_xtag_10_3_release_2023-12-21T17-09-11.541Z"
          availability_zone = "eu-west-2a"
          instance_profile_policies = concat(local.xtag_ec2.config.instance_profile_policies, [
            "Ec2PreprodWeblogicPolicy",
          ])
        })
        user_data_cloud_init = merge(local.xtag_ec2.user_data_cloud_init, {
          args = merge(local.xtag_ec2.user_data_cloud_init.args, {
            branch = "main"
          })
        })
        tags = merge(local.xtag_ec2.tags, {
          nomis-environment    = "preprod"
          oracle-db-hostname-a = "ppnomis-a.preproduction.nomis.service.justice.gov.uk"
          oracle-db-hostname-b = "ppnomis-b.preproduction.nomis.service.justice.gov.uk"
          oracle-db-name       = "PPCNOM"
          ndh-ems-hostname     = "pp-ems.preproduction.ndh.nomis.service.justice.gov.uk"
        })
      })
    }

    iam_policies = {
      Ec2LsastDatabasePolicy = {
        description = "Permissions required for Lsast Database EC2s"
        statements = [
          {
            effect = "Allow"
            actions = [
              "s3:GetBucketLocation",
              "s3:GetObject",
              "s3:GetObjectTagging",
              "s3:ListBucket",
            ]
            resources = [
              "arn:aws:s3:::nomis-db-backup-bucket*",
              "arn:aws:s3:::nomis-audit-archives*",
            ]
          },
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
              "arn:aws:secretsmanager:*:*:secret:/oracle/database/*LS/*",
              "arn:aws:secretsmanager:*:*:secret:/oracle/database/LS*/*",
            ]
          }
        ]
      }
      Ec2PreprodDatabasePolicy = {
        description = "Permissions required for Preprod Database EC2s"
        statements = [
          {
            effect = "Allow"
            actions = [
              "s3:GetBucketLocation",
              "s3:GetObject",
              "s3:GetObjectTagging",
              "s3:ListBucket",
            ]
            resources = [
              "arn:aws:s3:::nomis-db-backup-bucket*",
              "arn:aws:s3:::nomis-audit-archives*",
            ]
          },
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
              "arn:aws:secretsmanager:*:*:secret:/oracle/database/*PP/*",
              "arn:aws:secretsmanager:*:*:secret:/oracle/database/PP*/*",
            ]
          }
        ]
      }
      Ec2PreprodWeblogicPolicy = {
        description = "Permissions required for Preprod Weblogic EC2s"
        statements = concat(local.weblogic_iam_policy_statements, [
          {
            effect = "Allow"
            actions = [
              "secretsmanager:GetSecretValue",
              "secretsmanager:PutSecretValue",
            ]
            resources = [
              "arn:aws:secretsmanager:*:*:secret:/oracle/weblogic/preprod/*",
              "arn:aws:secretsmanager:*:*:secret:/oracle/database/*PP/weblogic-*",
              "arn:aws:secretsmanager:*:*:secret:/oracle/database/PP*/weblogic-*",
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
              "preprod-nomis-web-a-http-7777",
              # "preprod-nomis-web-b-http-7777",
            ]
            # /home/oracle/admin/scripts/lb_maintenance_mode.sh script on
            # weblogic servers can alter priorities to enable maintenance message
            rules = {
              preprod-nomis-web-a-http-7777 = {
                priority = 200
                actions = [{
                  type              = "forward"
                  target_group_name = "preprod-nomis-web-a-http-7777"
                }]
                conditions = [{
                  host_header = {
                    values = [
                      "preprod-nomis-web-a.preproduction.nomis.az.justice.gov.uk",
                      "preprod-nomis-web-a.preproduction.nomis.service.justice.gov.uk",
                      "c.preproduction.nomis.az.justice.gov.uk",
                      "c.preproduction.nomis.service.justice.gov.uk",
                      "c.pp-nomis.az.justice.gov.uk",
                    ]
                  }
                }]
              }
              preprod-nomis-web-b-http-7777 = {
                priority = 400
                actions = [{
                  type              = "forward"
                  target_group_name = "preprod-nomis-web-b-http-7777"
                }]
                conditions = [{
                  host_header = {
                    values = [
                      "preprod-nomis-web-b.preproduction.nomis.az.justice.gov.uk",
                      "preprod-nomis-web-b.preproduction.nomis.service.justice.gov.uk",
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
                    message_body = templatefile("templates/maintenance.html.tftpl", local.lb_maintenance_message_preproduction)
                    status_code  = "200"
                  }
                }]
                conditions = [{
                  host_header = {
                    values = [
                      "maintenance.preproduction.nomis.service.justice.gov.uk",
                      "preprod-nomis-web-a.preproduction.nomis.service.justice.gov.uk",
                      "preprod-nomis-web-b.preproduction.nomis.service.justice.gov.uk",
                      "c.preproduction.nomis.service.justice.gov.uk",
                      "c.pp-nomis.az.justice.gov.uk",
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
      "preproduction.nomis.az.justice.gov.uk" = {
        lb_alias_records = [
          { name = "maintenance", type = "A", lbs_map_key = "private" },
          { name = "preprod-nomis-web-a", type = "A", lbs_map_key = "private" },
          { name = "preprod-nomis-web-b", type = "A", lbs_map_key = "private" },
          { name = "c", type = "A", lbs_map_key = "private" },
        ]
      }
      "preproduction.nomis.service.justice.gov.uk" = {
        records = [
          { name = "lsnomis", type = "CNAME", ttl = "300", records = ["lsnomis-a.preproduction.nomis.service.justice.gov.uk"] },
          { name = "lsnomis-a", type = "CNAME", ttl = "300", records = ["lsast-nomis-db-1-a.nomis.hmpps-preproduction.modernisation-platform.service.justice.gov.uk"] },
          { name = "lsnomis-b", type = "CNAME", ttl = "300", records = ["lsast-nomis-db-1-b.nomis.hmpps-preproduction.modernisation-platform.service.justice.gov.uk"] },
          { name = "lsor", type = "CNAME", ttl = "300", records = ["lsor-a.preproduction.nomis.service.justice.gov.uk"] },
          { name = "lsor-a", type = "CNAME", ttl = "300", records = ["lsast-nomis-db-1-a.nomis.hmpps-preproduction.modernisation-platform.service.justice.gov.uk"] },
          { name = "lsor-b", type = "CNAME", ttl = "300", records = ["lsast-nomis-db-1-b.nomis.hmpps-preproduction.modernisation-platform.service.justice.gov.uk"] },
          { name = "lsmis", type = "CNAME", ttl = "300", records = ["lsmis-a.preproduction.nomis.service.justice.gov.uk"] },
          { name = "lsmis-a", type = "CNAME", ttl = "300", records = ["lsast-nomis-db-1-a.nomis.hmpps-preproduction.modernisation-platform.service.justice.gov.uk"] },
          { name = "lsmis-b", type = "CNAME", ttl = "300", records = ["lsast-nomis-db-1-b.nomis.hmpps-preproduction.modernisation-platform.service.justice.gov.uk"] },
          { name = "ppnomis", type = "CNAME", ttl = "300", records = ["ppnomis-a.preproduction.nomis.service.justice.gov.uk"] },
          { name = "ppnomis-a", type = "CNAME", ttl = "300", records = ["preprod-nomis-db-1-a.nomis.hmpps-preproduction.modernisation-platform.service.justice.gov.uk"] },
          { name = "ppnomis-b", type = "CNAME", ttl = "300", records = ["preprod-nomis-db-1-b.nomis.hmpps-preproduction.modernisation-platform.service.justice.gov.uk"] },
          { name = "ppndh", type = "CNAME", ttl = "300", records = ["ppndh-a.preproduction.nomis.service.justice.gov.uk"] },
          { name = "ppndh-a", type = "CNAME", ttl = "300", records = ["preprod-nomis-db-1-a.nomis.hmpps-preproduction.modernisation-platform.service.justice.gov.uk"] },
          { name = "ppndh-b", type = "CNAME", ttl = "300", records = ["preprod-nomis-db-1-b.nomis.hmpps-preproduction.modernisation-platform.service.justice.gov.uk"] },
          { name = "ppor", type = "CNAME", ttl = "300", records = ["ppor-a.preproduction.nomis.service.justice.gov.uk"] },
          { name = "ppor-a", type = "CNAME", ttl = "300", records = ["preprod-nomis-db-1-b.nomis.hmpps-preproduction.modernisation-platform.service.justice.gov.uk"] },
          { name = "ppor-b", type = "CNAME", ttl = "300", records = ["preprod-nomis-db-1-a.nomis.hmpps-preproduction.modernisation-platform.service.justice.gov.uk"] },
          { name = "pptrdat", type = "CNAME", ttl = "300", records = ["pptrdat-a.preproduction.nomis.service.justice.gov.uk"] },
          { name = "pptrdat-a", type = "CNAME", ttl = "300", records = ["preprod-nomis-db-1-a.nomis.hmpps-preproduction.modernisation-platform.service.justice.gov.uk"] },
          { name = "pptrdat-b", type = "CNAME", ttl = "300", records = ["preprod-nomis-db-1-b.nomis.hmpps-preproduction.modernisation-platform.service.justice.gov.uk"] },
          { name = "ppaudit", type = "CNAME", ttl = "300", records = ["ppaudit-a.preproduction.nomis.service.justice.gov.uk"] },
          { name = "ppaudit-a", type = "CNAME", ttl = "300", records = ["preprod-nomis-db-2-a.nomis.hmpps-preproduction.modernisation-platform.service.justice.gov.uk"] },
          { name = "ppaudit-b", type = "CNAME", ttl = "300", records = ["preprod-nomis-db-2-a.nomis.hmpps-preproduction.modernisation-platform.service.justice.gov.uk"] },
          { name = "ppmis", type = "CNAME", ttl = "300", records = ["ppmis-a.preproduction.nomis.service.justice.gov.uk"] },
          { name = "ppmis-a", type = "CNAME", ttl = "300", records = ["preprod-nomis-db-2-a.nomis.hmpps-preproduction.modernisation-platform.service.justice.gov.uk"] },
          { name = "ppmis-b", type = "CNAME", ttl = "300", records = ["preprod-nomis-db-2-a.nomis.hmpps-preproduction.modernisation-platform.service.justice.gov.uk"] },
          { name = "ppnomisapiro", type = "CNAME", ttl = "300", records = ["ppnomisapiro-a.preproduction.nomis.service.justice.gov.uk"] },
          { name = "ppnomisapiro-a", type = "CNAME", ttl = "300", records = ["preprod-nomis-db-1-b.nomis.hmpps-preproduction.modernisation-platform.service.justice.gov.uk"] },
          { name = "ppnomisapiro-b", type = "CNAME", ttl = "300", records = ["preprod-nomis-db-1-a.nomis.hmpps-preproduction.modernisation-platform.service.justice.gov.uk"] },
        ]
        lb_alias_records = [
          { name = "preprod-nomis-web-a", type = "A", lbs_map_key = "private" },
          { name = "preprod-nomis-web-b", type = "A", lbs_map_key = "private" },
          { name = "c", type = "A", lbs_map_key = "private" },
        ]
      }
    }

    s3_buckets = {
      nomis-audit-archives = {
        custom_kms_key = module.environment.kms_keys["general"].arn
        iam_policies   = module.baseline_presets.s3_iam_policies
        lifecycle_rule = [
          module.baseline_presets.s3_lifecycle_rules.ninety_day_standard_ia_ten_year_expiry
        ]
      }
      nomis-db-backup-bucket = {
        custom_kms_key = module.environment.kms_keys["general"].arn
        iam_policies   = module.baseline_presets.s3_iam_policies
      }
    }

    secretsmanager_secrets = {
      "/oracle/database/LSCNOM" = local.database_secretsmanager_secrets
      "/oracle/database/LSMIS"  = local.database_mis_secretsmanager_secrets

      "/oracle/weblogic/preprod"  = local.weblogic_secretsmanager_secrets
      "/oracle/database/PPCNOM"   = local.database_nomis_secretsmanager_secrets
      "/oracle/database/PPCNOMHA" = local.database_secretsmanager_secrets
      "/oracle/database/PPNDH"    = local.database_secretsmanager_secrets
      "/oracle/database/PPTRDAT"  = local.database_secretsmanager_secrets
      "/oracle/database/PPCNMAUD" = local.database_secretsmanager_secrets
      "/oracle/database/PPMIS"    = local.database_mis_secretsmanager_secrets
    }
  }
}
