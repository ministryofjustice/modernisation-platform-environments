locals {

  lb_maintenance_message_preproduction = {
    maintenance_title   = "Prison-NOMIS Environment Not Started"
    maintenance_message = "Preprod is available during working hours 7am-7pm. Please contact <a href=\"https://moj.enterprise.slack.com/archives/C6D94J81E\">#ask-digital-studio-ops</a> slack channel if environment is unexpectedly down. See <a href=\"https://dsdmoj.atlassian.net/wiki/spaces/DSTT/pages/4978343956\">confluence</a> for more details"
  }

  baseline_presets_preproduction = {
    options = {
      enable_xsiam_cloudwatch_integration = true
      enable_xsiam_s3_integration         = true
      route53_resolver_rules = {
        outbound-data-and-private-subnets = ["azure-fixngo-domain", "infra-int-domain"]
      }
      sns_topics = {
        pagerduty_integrations = {
          pagerduty = "nomis-preproduction"
        }
      }
    }
  }

  # please keep resources in alphabetical order
  baseline_preproduction = {

    acm_certificates = {
      nomis_wildcard_cert_v2 = {
        cloudwatch_metric_alarms            = module.baseline_presets.cloudwatch_metric_alarms.acm
        domain_name                         = "*.preproduction.nomis.service.justice.gov.uk"
        external_validation_records_created = true
        subject_alternate_names = [
          "*.nomis.hmpps-preproduction.modernisation-platform.service.justice.gov.uk",
          "*.pp-nomis.az.justice.gov.uk",
          "*.lsast-nomis.az.justice.gov.uk",
        ]
        tags = {
          description = "wildcard cert for nomis preproduction domains"
        }
      }
    }

    cloudwatch_dashboards = {
      "CloudWatch-Default" = {
        periodOverride = "auto"
        start          = "-PT6H"
        widget_groups = [
          module.baseline_presets.cloudwatch_dashboard_widget_groups.lb,
          local.cloudwatch_dashboard_widget_groups.db,
          local.cloudwatch_dashboard_widget_groups.xtag,
          local.cloudwatch_dashboard_widget_groups.asg,
          module.baseline_presets.cloudwatch_dashboard_widget_groups.ssm_command,
        ]
      }
    }

    ec2_autoscaling_groups = {
      # ACTIVE (blue deployment)
      lsast-nomis-web-a = merge(local.ec2_autoscaling_groups.web, {
        autoscaling_group = merge(local.ec2_autoscaling_groups.web.autoscaling_group, {
          desired_capacity = 0 # started on demand
        })
        # cloudwatch_metric_alarms = local.cloudwatch_metric_alarms.web
        config = merge(local.ec2_autoscaling_groups.web.config, {
          ami_name = "nomis_rhel_6_10_weblogic_appserver_10_3_release_2023-03-15T17-18-22.178Z"
          instance_profile_policies = concat(local.ec2_autoscaling_groups.web.config.instance_profile_policies, [
            "Ec2LsastWeblogicPolicy",
          ])
        })
        user_data_cloud_init = merge(local.ec2_autoscaling_groups.web.user_data_cloud_init, {
          args = merge(local.ec2_autoscaling_groups.web.user_data_cloud_init.args, {
            branch = "main"
          })
        })
        tags = merge(local.ec2_autoscaling_groups.web.tags, {
          nomis-environment    = "lsast"
          oracle-db-hostname-a = "lsnomis-a.preproduction.nomis.service.justice.gov.uk"
          oracle-db-hostname-b = "lsnomis-b.preproduction.nomis.service.justice.gov.uk"
          oracle-db-name       = "LSCNOM"
        })
      })

      # ACTIVE (blue deployment)
      preprod-nomis-web-a = merge(local.ec2_autoscaling_groups.web, {
        autoscaling_group = merge(local.ec2_autoscaling_groups.web.autoscaling_group, {
          desired_capacity = 1
          max_size         = 1
        })
        cloudwatch_metric_alarms = local.cloudwatch_metric_alarms.web
        config = merge(local.ec2_autoscaling_groups.web.config, {
          ami_name = "nomis_rhel_6_10_weblogic_appserver_10_3_release_2023-03-15T17-18-22.178Z"
          instance_profile_policies = concat(local.ec2_autoscaling_groups.web.config.instance_profile_policies, [
            "Ec2PreprodWeblogicPolicy",
          ])
        })
        user_data_cloud_init = merge(local.ec2_autoscaling_groups.web.user_data_cloud_init, {
          args = merge(local.ec2_autoscaling_groups.web.user_data_cloud_init.args, {
            branch = "main"
          })
        })
        tags = merge(local.ec2_autoscaling_groups.web.tags, {
          nomis-environment    = "preprod"
          oracle-db-hostname-a = "ppnomis-a.preproduction.nomis.service.justice.gov.uk"
          oracle-db-hostname-b = "ppnomis-b.preproduction.nomis.service.justice.gov.uk"
          oracle-db-name       = "PPCNOM"
        })
      })

      # NOT-ACTIVE (green deployment)
      preprod-nomis-web-b = merge(local.ec2_autoscaling_groups.web, {
        autoscaling_group = merge(local.ec2_autoscaling_groups.web.autoscaling_group, {
          desired_capacity = 0
          max_size         = 0

          initial_lifecycle_hooks = {
            "ready-hook" = {
              default_result       = "ABANDON"
              heartbeat_timeout    = 7200
              lifecycle_transition = "autoscaling:EC2_INSTANCE_LAUNCHING"
            }
          }

          # instance_refresh = {
          #   strategy               = "Rolling"
          #   min_healthy_percentage = 50
          # }
        })
        # cloudwatch_metric_alarms = local.cloudwatch_metric_alarms.web
        config = merge(local.ec2_autoscaling_groups.web.config, {
          ami_name = "nomis_rhel_6_10_weblogic_appserver_10_3_release_2023-03-15T17-18-22.178Z"
          instance_profile_policies = concat(local.ec2_autoscaling_groups.web.config.instance_profile_policies, [
            "Ec2PreprodWeblogicPolicy",
          ])
        })
        user_data_cloud_init = merge(local.ec2_autoscaling_groups.web.user_data_cloud_init, {
          args = merge(local.ec2_autoscaling_groups.web.user_data_cloud_init.args, {
            branch = "main"
          })
        })
        tags = merge(local.ec2_autoscaling_groups.web.tags, {
          nomis-environment    = "preprod"
          oracle-db-hostname-a = "ppnomis-a.preproduction.nomis.service.justice.gov.uk"
          oracle-db-hostname-b = "ppnomis-b.preproduction.nomis.service.justice.gov.uk"
          oracle-db-name       = "PPCNOM"
        })
      })

      preprod-nomis-client-a = merge(local.ec2_autoscaling_groups.client, {
        tags = merge(local.ec2_autoscaling_groups.client.tags, {
          domain-name = "azure.hmpp.root"
        })
      })
    }

    ec2_instances = {
      lsast-nomis-db-1-a = merge(local.ec2_instances.db, {
        #cloudwatch_metric_alarms = merge(
        #  local.cloudwatch_metric_alarms.db,
        #  local.cloudwatch_metric_alarms.db_connected,
        #)
        config = merge(local.ec2_instances.db.config, {
          ami_name          = "nomis_rhel_7_9_oracledb_11_2_release_2023-07-02T00-00-39.521Z"
          availability_zone = "eu-west-2a"
          instance_profile_policies = concat(local.ec2_instances.db.config.instance_profile_policies, [
            "Ec2LsastDatabasePolicy",
          ])
        })
        ebs_volumes = merge(local.ec2_instances.db.ebs_volumes, {
          "/dev/sdb" = { label = "app", size = 100 }
          "/dev/sdc" = { label = "app", size = 500 }
        })
        ebs_volume_config = merge(local.ec2_instances.db.ebs_volume_config, {
          data  = { total_size = 5000 }
          flash = { total_size = 500 }
        })
        instance = merge(local.ec2_instances.db.instance, {
          disable_api_termination = true
          instance_type           = "r6i.2xlarge"
        })
        tags = merge(local.ec2_instances.db.tags, {
          description         = "lsast database for CNOM and MIS"
          instance-scheduling = "skip-scheduling"
          misload-dbname      = "LSMIS"
          nomis-environment   = "lsast"
          oracle-sids         = "LSCNOM LSMIS"
        })
      })

      preprod-nomis-db-1-a = merge(local.ec2_instances.db, {
        cloudwatch_metric_alarms = merge(
          local.cloudwatch_metric_alarms.db,
          local.cloudwatch_metric_alarms.db_connected,
        )
        config = merge(local.ec2_instances.db.config, {
          ami_name          = "nomis_rhel_7_9_oracledb_11_2_release_2023-07-02T00-00-39.521Z"
          availability_zone = "eu-west-2a"
          instance_profile_policies = concat(local.ec2_instances.db.config.instance_profile_policies, [
            "Ec2PreprodDatabasePolicy",
          ])
        })
        ebs_volumes = merge(local.ec2_instances.db.ebs_volumes, {
          "/dev/sdb" = { label = "app", size = 100 }
          "/dev/sdc" = { label = "app", size = 1000 }
        })
        ebs_volume_config = merge(local.ec2_instances.db.ebs_volume_config, {
          data  = { total_size = 4000 }
          flash = { total_size = 1000 }
        })
        instance = merge(local.ec2_instances.db.instance, {
          disable_api_termination = true
          instance_type           = "r6i.2xlarge"
        })
        tags = merge(local.ec2_instances.db.tags, {
          description         = "pre-production database for CNOMPP"
          instance-scheduling = "skip-scheduling"
          nomis-environment   = "preprod"
          oracle-sids         = "PPCNOM PPNDH PPTRDAT"
          update-ssm-agent    = "patchgroup2"
        })
      })

      preprod-nomis-db-1-b = merge(local.ec2_instances.db, {
        cloudwatch_metric_alarms = merge(
          local.cloudwatch_metric_alarms.db,
        )
        config = merge(local.ec2_instances.db.config, {
          ami_name          = "nomis_rhel_7_9_oracledb_11_2_release_2023-07-02T00-00-39.521Z"
          availability_zone = "eu-west-2b"
          instance_profile_policies = concat(local.ec2_instances.db.config.instance_profile_policies, [
            "Ec2PreprodDatabasePolicy",
          ])
        })
        ebs_volumes = merge(local.ec2_instances.db.ebs_volumes, {
          "/dev/sdb" = { label = "app", size = 100 }
          "/dev/sdc" = { label = "app", size = 500 }
        })
        ebs_volume_config = merge(local.ec2_instances.db.ebs_volume_config, {
          data  = { total_size = 3000 }
          flash = { total_size = 1000 }
        })
        instance = merge(local.ec2_instances.db.instance, {
          disable_api_termination = true
          instance_type           = "r6i.2xlarge"
        })
        tags = merge(local.ec2_instances.db.tags, {
          description         = "Disaster-Recovery/High-Availability pre-production database for CNOMPP"
          instance-scheduling = "skip-scheduling"
          nomis-environment   = "preprod"
          oracle-sids         = "PPCNOMHA"
        })
      })

      preprod-nomis-db-2-a = merge(local.ec2_instances.db, {
        cloudwatch_metric_alarms = merge(
          local.cloudwatch_metric_alarms.db,
          local.cloudwatch_metric_alarms.db_connected,
          local.cloudwatch_metric_alarms.db_misload,
        )
        config = merge(local.ec2_instances.db.config, {
          ami_name          = "nomis_rhel_7_9_oracledb_11_2_release_2023-07-02T00-00-39.521Z"
          availability_zone = "eu-west-2a"
          instance_profile_policies = concat(local.ec2_instances.db.config.instance_profile_policies, [
            "Ec2PreprodDatabasePolicy",
          ])
        })
        ebs_volumes = merge(local.ec2_instances.db.ebs_volumes, {
          "/dev/sdb" = { label = "app", size = 100 }
          "/dev/sdc" = { label = "app", size = 512 }
        })
        ebs_volume_config = merge(local.ec2_instances.db.ebs_volume_config, {
          data  = { total_size = 4000 }
          flash = { total_size = 1000 }
        })
        instance = merge(local.ec2_instances.db.instance, {
          disable_api_termination = true
          instance_type           = "r6i.2xlarge"
        })
        tags = merge(local.ec2_instances.db.tags, {
          description         = "PreProduction NOMIS MIS and Audit database"
          instance-scheduling = "skip-scheduling"
          misload-dbname      = "PPMIS"
          nomis-environment   = "preprod"
          oracle-sids         = "PPMIS PPCNMAUD"
          update-ssm-agent    = "patchgroup2"
        })
      })

      preprod-nomis-xtag-a = merge(local.ec2_instances.xtag, {
        cloudwatch_metric_alarms = local.cloudwatch_metric_alarms.xtag
        config = merge(local.ec2_instances.xtag.config, {
          ami_name          = "nomis_rhel_7_9_weblogic_xtag_10_3_release_2023-12-21T17-09-11.541Z"
          availability_zone = "eu-west-2a"
          instance_profile_policies = concat(local.ec2_instances.xtag.config.instance_profile_policies, [
            "Ec2PreprodWeblogicPolicy",
          ])
        })
        user_data_cloud_init = merge(local.ec2_instances.xtag.user_data_cloud_init, {
          args = merge(local.ec2_instances.xtag.user_data_cloud_init.args, {
            branch = "main"
          })
        })
        tags = merge(local.ec2_instances.xtag.tags, {
          instance-scheduling  = "skip-scheduling"
          ndh-ems-hostname     = "pp-ems.preproduction.ndh.nomis.service.justice.gov.uk"
          nomis-environment    = "preprod"
          oracle-db-hostname-a = "ppnomis-a.preproduction.nomis.service.justice.gov.uk"
          oracle-db-hostname-b = "ppnomis-b.preproduction.nomis.service.justice.gov.uk"
          oracle-db-name       = "PPCNOM"
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
              "secretsmanager:GetSecretValue",
              "secretsmanager:PutSecretValue",
            ]
            resources = [
              "arn:aws:secretsmanager:*:*:secret:/oracle/database/LS*/*",
            ]
          }
        ]
      }
      Ec2LsastWeblogicPolicy = {
        description = "Permissions required for Preprod Weblogic EC2s"
        statements = concat(local.iam_policy_statements_ec2.web, [
          {
            effect = "Allow"
            actions = [
              "secretsmanager:GetSecretValue",
              "secretsmanager:PutSecretValue",
            ]
            resources = [
              "arn:aws:secretsmanager:*:*:secret:/oracle/weblogic/lsast/*",
              "arn:aws:secretsmanager:*:*:secret:/oracle/database/LS*/weblogic-*",
            ]
          }
        ])
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
              "secretsmanager:GetSecretValue",
              "secretsmanager:PutSecretValue",
            ]
            resources = [
              "arn:aws:secretsmanager:*:*:secret:/oracle/database/PP*/*",
            ]
          }
        ]
      }
      Ec2PreprodWeblogicPolicy = {
        description = "Permissions required for Preprod Weblogic EC2s"
        statements = concat(local.iam_policy_statements_ec2.web, [
          {
            effect = "Allow"
            actions = [
              "secretsmanager:GetSecretValue",
              "secretsmanager:PutSecretValue",
            ]
            resources = [
              "arn:aws:secretsmanager:*:*:secret:/oracle/weblogic/preprod/*",
              "arn:aws:secretsmanager:*:*:secret:/oracle/database/PP*/weblogic-*",
            ]
          }
        ])
      }
    }

    lbs = {
      private = merge(local.lbs.private, {

        s3_notification_queues = {
          "cortex-xsiam-s3-alb-log-collection" = {
            events    = ["s3:ObjectCreated:*"]
            queue_arn = "cortex-xsiam-s3-alb-log-collection"
          }
        }

        listeners = merge(local.lbs.private.listeners, {
          https = merge(local.lbs.private.listeners.https, {
            alarm_target_group_names  = [] # don't enable as environments are powered up/down frequently
            certificate_names_or_arns = ["nomis_wildcard_cert_v2"]
            cloudwatch_metric_alarms  = module.baseline_presets.cloudwatch_metric_alarms.lb

            # /home/oracle/admin/scripts/lb_maintenance_mode.sh script on
            # weblogic servers can alter priorities to enable maintenance message
            rules = {
              lsast-nomis-web-a-http-7777 = {
                priority = 1150 # reduce by 1000 to make active
                actions = [{
                  type              = "forward"
                  target_group_name = "lsast-nomis-web-a-http-7777"
                }]
                conditions = [{
                  host_header = {
                    values = [
                      "lsast-nomis-web-a.preproduction.nomis.service.justice.gov.uk",
                      "c-lsast.preproduction.nomis.service.justice.gov.uk",
                      "c.lsast-nomis.az.justice.gov.uk",
                    ]
                  }
                }]
              }
              preprod-nomis-web-a-http-7777 = {
                priority = 200
                actions = [{
                  type              = "forward"
                  target_group_name = "preprod-nomis-web-a-http-7777"
                }]
                conditions = [{
                  host_header = {
                    values = [
                      "preprod-nomis-web-a.preproduction.nomis.service.justice.gov.uk",
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
                      "c.pp-nomis.az.justice.gov.uk",
                      "c.lsast-nomis.az.justice.gov.uk",
                      "c.preproduction.nomis.service.justice.gov.uk",
                      "c-lsast.preproduction.nomis.service.justice.gov.uk",
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
          { name = "ppnomisapiro-a", type = "CNAME", ttl = "300", records = ["preprod-nomis-db-1-a.nomis.hmpps-preproduction.modernisation-platform.service.justice.gov.uk"] },
          { name = "ppnomisapiro-b", type = "CNAME", ttl = "300", records = ["preprod-nomis-db-1-a.nomis.hmpps-preproduction.modernisation-platform.service.justice.gov.uk"] },
        ]
        lb_alias_records = [
          { name = "preprod-nomis-web-a", type = "A", lbs_map_key = "private" },
          { name = "preprod-nomis-web-b", type = "A", lbs_map_key = "private" },
          { name = "c", type = "A", lbs_map_key = "private" },
          { name = "c-lsast", type = "A", lbs_map_key = "private" },
        ]
      }
    }

    secretsmanager_secrets = {
      "/oracle/weblogic/lsast"  = local.secretsmanager_secrets.web
      "/oracle/database/LSCNOM" = local.secretsmanager_secrets.db_cnom
      "/oracle/database/LSMIS"  = local.secretsmanager_secrets.db_mis

      "/oracle/weblogic/preprod"  = local.secretsmanager_secrets.web
      "/oracle/database/PPCNOM"   = local.secretsmanager_secrets.db_cnom
      "/oracle/database/PPCNOMHA" = local.secretsmanager_secrets.db
      "/oracle/database/PPNDH"    = local.secretsmanager_secrets.db
      "/oracle/database/PPTRDAT"  = local.secretsmanager_secrets.db
      "/oracle/database/PPCNMAUD" = local.secretsmanager_secrets.db
      "/oracle/database/PPMIS"    = local.secretsmanager_secrets.db_mis
    }
  }
}
