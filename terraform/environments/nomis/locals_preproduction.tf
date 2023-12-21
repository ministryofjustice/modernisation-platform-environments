# nomis-preproduction environment settings
locals {

  # baseline presets config
  preproduction_baseline_presets_options = {
    sns_topics = {
      pagerduty_integrations = {
        dso_pagerduty               = "nomis_alarms"
        dba_pagerduty               = "hmpps_shef_dba_low_priority"
        dba_high_priority_pagerduty = "hmpps_shef_dba_low_priority"
      }
    }
  }

  # baseline config
  preproduction_config = {

    baseline_s3_buckets = {
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

    baseline_acm_certificates = {
      nomis_wildcard_cert = {
        # domain_name limited to 64 chars so use modernisation platform domain for this
        # and put the wildcard in the san
        domain_name = module.environment.domains.public.modernisation_platform
        subject_alternate_names = [
          "*.${module.environment.domains.public.application_environment}",
          "*.${local.environment}.nomis.service.justice.gov.uk",
          "*.${local.environment}.nomis.az.justice.gov.uk",
          "*.pp-nomis.az.justice.gov.uk",
          "*.lsast-nomis.az.justice.gov.uk",
        ]
        external_validation_records_created = true
        cloudwatch_metric_alarms            = module.baseline_presets.cloudwatch_metric_alarms.acm
        tags = {
          description = "wildcard cert for nomis ${local.environment} domains"
        }
      }
    }

    baseline_iam_policies = {
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
        statements = [
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
        ]
      }
    }

    baseline_secretsmanager_secrets = {
      "/oracle/weblogic/preprod"  = local.weblogic_secretsmanager_secrets
      "/oracle/database/PPCNOM"   = local.database_nomis_secretsmanager_secrets
      "/oracle/database/PPNDH"    = local.database_secretsmanager_secrets
      "/oracle/database/PPTRDAT"  = local.database_secretsmanager_secrets
      "/oracle/database/PPCNMAUD" = local.database_secretsmanager_secrets
      "/oracle/database/PPMIS"    = local.database_mis_secretsmanager_secrets
    }

    baseline_ec2_autoscaling_groups = {
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
        instance = merge(local.weblogic_ec2.instance, {
          instance_type = "t2.xlarge"
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
        autoscaling_group = merge(local.weblogic_ec2.autoscaling_group, {
          desired_capacity = 0
        })
        # cloudwatch_metric_alarms = local.weblogic_cloudwatch_metric_alarms
        config = merge(local.weblogic_ec2.config, {
          ami_name = "nomis_rhel_6_10_weblogic_appserver_10_3_release_*"
          instance_profile_policies = concat(local.weblogic_ec2.config.instance_profile_policies, [
            "Ec2PreprodWeblogicPolicy",
          ])
        })
        instance = merge(local.weblogic_ec2.instance, {
          instance_type = "t2.xlarge"
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
      preprod-nomis-xtag-a = merge(local.xtag_ec2, {
        autoscaling_group = merge(local.xtag_ec2.autoscaling_group, {
          desired_capacity = 1
        })
        cloudwatch_metric_alarms = local.xtag_cloudwatch_metric_alarms
        config = merge(local.xtag_ec2.config, {
          ami_name = "nomis_rhel_7_9_weblogic_xtag_10_3_release_2023-07-19T09-01-29.168Z"
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
          ndh-ems-hostname     = "PPPML00009.azure.hmpp.root" # preprod NDH is currently down/broken
        })
      })

      preprod-jumpserver-a = merge(local.jumpserver_ec2, {
        config = merge(local.jumpserver_ec2.config, {
          user_data_raw = base64encode(templatefile("./templates/jumpserver-user-data.yaml.tftpl", {
            ie_compatibility_mode_site_list = join(",", [
              "preprod-nomis-web-a.preproduction.nomis.service.justice.gov.uk/forms/frmservlet?config=tag",
              "preprod-nomis-web-b.preproduction.nomis.service.justice.gov.uk/forms/frmservlet?config=tag",
              "c.pp-nomis.az.justice.gov.uk/forms/frmservlet?config=tag",
              "c.preproduction.nomis.service.justice.gov.uk/forms/frmservlet?config=tag",
            ])
            ie_trusted_domains = join(",", [
              "*.nomis.hmpps-preproduction.modernisation-platform.justice.gov.uk",
              "*.nomis.service.justice.gov.uk",
              "*.nomis.az.justice.gov.uk",
            ])
            desktop_shortcuts = join(",", [
              "Preprod NOMIS|https://c.preproduction.nomis.service.justice.gov.uk/forms/frmservlet?config=tag",
            ])
          }))
        })
      })
    }

    baseline_ec2_instances = {
      preprod-nomis-db-1-a = merge(local.database_ec2, {
        cloudwatch_metric_alarms = merge(
          local.database_ec2_cloudwatch_metric_alarms.standard,
          local.database_ec2_cloudwatch_metric_alarms.db_connected,
        )
        config = merge(local.database_ec2.config, {
          ami_name          = "nomis_rhel_7_9_oracledb_11_2_release_2023-07-02T00-00-39.521Z"
          availability_zone = "${local.region}a"
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
          instance_type = "r6i.2xlarge"
        })
        tags = merge(local.database_ec2.tags, {
          nomis-environment = "preprod"
          description       = "pre-production database for CNOMPP"
          oracle-sids       = "PPCNOM PPNDH PPTRDAT"
        })
      })

      preprod-nomis-db-1-b = merge(local.database_ec2, {
        # cloudwatch_metric_alarms = merge(
        #   local.database_ec2_cloudwatch_metric_alarms.standard,
        # )
        config = merge(local.database_ec2.config, {
          ami_name          = "nomis_rhel_7_9_oracledb_11_2_release_2023-07-02T00-00-39.521Z"
          availability_zone = "${local.region}b"
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
          instance_type = "r6i.2xlarge"
        })
        tags = merge(local.database_ec2.tags, {
          nomis-environment = "preprod"
          description       = "Disaster-Recovery/High-Availability pre-production database for CNOMPP"
          oracle-sids       = "" # TODO
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
          availability_zone = "${local.region}a"
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
          instance_type = "r6i.2xlarge"
        })
        tags = merge(local.database_ec2.tags, {
          nomis-environment = "preprod"
          description       = "PreProduction NOMIS MIS and Audit database"
          oracle-sids       = "PPMIS PPCNMAUD"
          misload-dbname    = "PPMIS"
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
                "preprod-nomis-web-a-http-7777",
                # "preprod-nomis-web-b-http-7777",
              ]
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
              }
          })
        }
      }
    }

    baseline_route53_zones = {
      "preproduction.nomis.az.justice.gov.uk" = {
        lb_alias_records = [
          { name = "preprod-nomis-web-a", type = "A", lbs_map_key = "private" },
          { name = "preprod-nomis-web-b", type = "A", lbs_map_key = "private" },
          { name = "c", type = "A", lbs_map_key = "private" },
        ]
      }
      "preproduction.nomis.service.justice.gov.uk" = {
        records = [
          { name = "ppnomis", type = "CNAME", ttl = "300", records = ["ppnomis-a.preproduction.nomis.service.justice.gov.uk"] },
          { name = "ppnomis-a", type = "CNAME", ttl = "300", records = ["preprod-nomis-db-1-a.nomis.hmpps-preproduction.modernisation-platform.service.justice.gov.uk"] },
          { name = "ppnomis-b", type = "CNAME", ttl = "300", records = ["preprod-nomis-db-1-a.nomis.hmpps-preproduction.modernisation-platform.service.justice.gov.uk"] },
          { name = "ppndh", type = "CNAME", ttl = "300", records = ["ppndh-a.preproduction.nomis.service.justice.gov.uk"] },
          { name = "ppndh-a", type = "CNAME", ttl = "300", records = ["preprod-nomis-db-1-a.nomis.hmpps-preproduction.modernisation-platform.service.justice.gov.uk"] },
          { name = "ppndh-b", type = "CNAME", ttl = "300", records = ["preprod-nomis-db-1-a.nomis.hmpps-preproduction.modernisation-platform.service.justice.gov.uk"] },
          { name = "ppor", type = "CNAME", ttl = "300", records = ["ppor-a.preproduction.nomis.service.justice.gov.uk"] },
          { name = "ppor-a", type = "CNAME", ttl = "300", records = ["preprod-nomis-db-1-a.nomis.hmpps-preproduction.modernisation-platform.service.justice.gov.uk"] },
          { name = "ppor-b", type = "CNAME", ttl = "300", records = ["preprod-nomis-db-1-a.nomis.hmpps-preproduction.modernisation-platform.service.justice.gov.uk"] },
          { name = "pptrdat", type = "CNAME", ttl = "300", records = ["pptrdat-a.preproduction.nomis.service.justice.gov.uk"] },
          { name = "pptrdat-a", type = "CNAME", ttl = "300", records = ["preprod-nomis-db-1-a.nomis.hmpps-preproduction.modernisation-platform.service.justice.gov.uk"] },
          { name = "pptrdat-b", type = "CNAME", ttl = "300", records = ["preprod-nomis-db-1-a.nomis.hmpps-preproduction.modernisation-platform.service.justice.gov.uk"] },
          { name = "ppaudit", type = "CNAME", ttl = "300", records = ["ppaudit-a.preproduction.nomis.service.justice.gov.uk"] },
          { name = "ppaudit-a", type = "CNAME", ttl = "300", records = ["preprod-nomis-db-2-a.nomis.hmpps-preproduction.modernisation-platform.service.justice.gov.uk"] },
          { name = "ppaudit-b", type = "CNAME", ttl = "300", records = ["preprod-nomis-db-2-a.nomis.hmpps-preproduction.modernisation-platform.service.justice.gov.uk"] },
          { name = "ppmis", type = "CNAME", ttl = "300", records = ["ppmis-a.preproduction.nomis.service.justice.gov.uk"] },
          { name = "ppmis-a", type = "CNAME", ttl = "300", records = ["preprod-nomis-db-2-a.nomis.hmpps-preproduction.modernisation-platform.service.justice.gov.uk"] },
          { name = "ppmis-b", type = "CNAME", ttl = "300", records = ["preprod-nomis-db-2-a.nomis.hmpps-preproduction.modernisation-platform.service.justice.gov.uk"] },
          { name = "ppnomisapiro", type = "CNAME", ttl = "300", records = ["ppnomisapiro-a.preproduction.nomis.service.justice.gov.uk"] },
          { name = "ppnomisapiro-a", type = "CNAME", ttl = "300", records = ["preprod-nomis-db-1-b.nomis.hmpps-preproduction.modernisation-platform.service.justice.gov.uk"] },
          { name = "ppnomisapiro-b", type = "CNAME", ttl = "300", records = ["preprod-nomis-db-1-b.nomis.hmpps-preproduction.modernisation-platform.service.justice.gov.uk"] },
        ]
        lb_alias_records = [
          { name = "preprod-nomis-web-a", type = "A", lbs_map_key = "private" },
          { name = "preprod-nomis-web-b", type = "A", lbs_map_key = "private" },
          { name = "c", type = "A", lbs_map_key = "private" },
        ]
      }
    }
  }
}
