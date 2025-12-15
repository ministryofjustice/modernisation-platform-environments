locals {

  lb_maintenance_message_test = {
    maintenance_title   = "Prison-NOMIS Environment Not Started"
    maintenance_message = "T1 and T2 are rarely used so are started on demand. T3 is available during working hours 7am-7pm. Please contact <a href=\"https://moj.enterprise.slack.com/archives/C6D94J81E\">#ask-digital-studio-ops</a> slack channel if environment is unexpectedly down. See <a href=\"https://dsdmoj.atlassian.net/wiki/spaces/DSTT/pages/4978343956\">confluence</a> for more details"
  }

  baseline_presets_test = {
    options = {
      sns_topics = {
        pagerduty_integrations = {
          pagerduty = "nomis-test"
        }
      }
    }
  }

  # please keep resources in alphabetical order
  baseline_test = {

    acm_certificates = {
      nomis_wildcard_cert_v3 = {
        cloudwatch_metric_alarms = module.baseline_presets.cloudwatch_metric_alarms.acm
        domain_name              = "*.test.nomis.service.justice.gov.uk"
        subject_alternate_names = [
          "*.nomis.hmpps-test.modernisation-platform.service.justice.gov.uk",
        ]
        tags = {
          description = "wildcard cert for nomis test domains"
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
      # NOT-ACTIVE (blue deployment)
      t1-nomis-web-a = merge(local.ec2_autoscaling_groups.web, {
        autoscaling_group = merge(local.ec2_autoscaling_groups.web.autoscaling_group, {
          desired_capacity = 0
          max_size         = 0
        })
        # cloudwatch_metric_alarms = local.cloudwatch_metric_alarms.web
        config = merge(local.ec2_autoscaling_groups.web.config, {
          ami_name = "nomis_rhel_6_10_weblogic_appserver_10_3_release_2023-03-15T17-18-22.178Z"
          instance_profile_policies = concat(local.ec2_autoscaling_groups.web.config.instance_profile_policies, [
            "Ec2T1WeblogicPolicy",
          ])
        })
        instance = merge(local.ec2_autoscaling_groups.web.instance, {
        })
        user_data_cloud_init = merge(local.ec2_autoscaling_groups.web.user_data_cloud_init, {
          args = merge(local.ec2_autoscaling_groups.web.user_data_cloud_init.args, {
            branch = "main"
          })
        })
        tags = merge(local.ec2_autoscaling_groups.web.tags, {
          nomis-environment    = "t1"
          oracle-db-hostname-a = "t1nomis-a.test.nomis.service.justice.gov.uk"
          oracle-db-hostname-b = "t1nomis-b.test.nomis.service.justice.gov.uk"
          oracle-db-name       = "T1CNOM"
        })
      })

      # ACTIVE (green deployment)
      t1-nomis-web-b = merge(local.ec2_autoscaling_groups.web, {
        autoscaling_group = merge(local.ec2_autoscaling_groups.web.autoscaling_group, {
          desired_capacity = 0 # started on demand
        })
        cloudwatch_metric_alarms = local.cloudwatch_metric_alarms.web
        config = merge(local.ec2_autoscaling_groups.web.config, {
          ami_name = "nomis_rhel_6_10_weblogic_appserver_10_3_release_2023-03-15T17-18-22.178Z"
          instance_profile_policies = concat(local.ec2_autoscaling_groups.web.config.instance_profile_policies, [
            "Ec2T1WeblogicPolicy",
          ])
        })
        instance = merge(local.ec2_autoscaling_groups.web.instance, {
        })
        user_data_cloud_init = merge(local.ec2_autoscaling_groups.web.user_data_cloud_init, {
          args = merge(local.ec2_autoscaling_groups.web.user_data_cloud_init.args, {
            branch = "main"
          })
        })
        tags = merge(local.ec2_autoscaling_groups.web.tags, {
          nomis-environment    = "t1"
          oracle-db-hostname-a = "t1nomis-a.test.nomis.service.justice.gov.uk"
          oracle-db-hostname-b = "t1nomis-b.test.nomis.service.justice.gov.uk"
          oracle-db-name       = "T1CNOM"
        })
      })

      # NOT-ACTIVE (blue deployment)
      t2-nomis-web-a = merge(local.ec2_autoscaling_groups.web, {
        autoscaling_group = merge(local.ec2_autoscaling_groups.web.autoscaling_group, {
          desired_capacity = 0
        })
        # cloudwatch_metric_alarms = local.cloudwatch_metric_alarms.web
        config = merge(local.ec2_autoscaling_groups.web.config, {
          ami_name = "nomis_rhel_6_10_weblogic_appserver_10_3_release_2023-03-15T17-18-22.178Z"
          instance_profile_policies = concat(local.ec2_autoscaling_groups.web.config.instance_profile_policies, [
            "Ec2T2WeblogicPolicy",
          ])
        })
        instance = merge(local.ec2_autoscaling_groups.web.instance, {
        })
        user_data_cloud_init = merge(local.ec2_autoscaling_groups.web.user_data_cloud_init, {
          args = merge(local.ec2_autoscaling_groups.web.user_data_cloud_init.args, {
            branch = "main"
          })
        })
        tags = merge(local.ec2_autoscaling_groups.web.tags, {
          nomis-environment    = "t2"
          oracle-db-hostname-a = "t2nomis-a.test.nomis.service.justice.gov.uk"
          oracle-db-hostname-b = "t2nomis-b.test.nomis.service.justice.gov.uk"
          oracle-db-name       = "T2CNOM"
        })
      })

      # ACTIVE (green deployment)
      t2-nomis-web-b = merge(local.ec2_autoscaling_groups.web, {
        autoscaling_group = merge(local.ec2_autoscaling_groups.web.autoscaling_group, {
          desired_capacity = 0
        })
        cloudwatch_metric_alarms = local.cloudwatch_metric_alarms.web
        config = merge(local.ec2_autoscaling_groups.web.config, {
          ami_name = "nomis_rhel_6_10_weblogic_appserver_10_3_release_2023-03-15T17-18-22.178Z"
          instance_profile_policies = concat(local.ec2_autoscaling_groups.web.config.instance_profile_policies, [
            "Ec2T2WeblogicPolicy",
          ])
        })
        instance = merge(local.ec2_autoscaling_groups.web.instance, {
        })
        user_data_cloud_init = merge(local.ec2_autoscaling_groups.web.user_data_cloud_init, {
          args = merge(local.ec2_autoscaling_groups.web.user_data_cloud_init.args, {
            branch = "main"
          })
        })
        tags = merge(local.ec2_autoscaling_groups.web.tags, {
          nomis-environment    = "t2"
          oracle-db-hostname-a = "t2nomis-a.test.nomis.service.justice.gov.uk"
          oracle-db-hostname-b = "t2nomis-b.test.nomis.service.justice.gov.uk"
          oracle-db-name       = "T2CNOM"
        })
      })

      # NOT-ACTIVE (blue deployment)
      t3-nomis-web-a = merge(local.ec2_autoscaling_groups.web, {
        autoscaling_group = merge(local.ec2_autoscaling_groups.web.autoscaling_group, {
          desired_capacity = 0
        })
        # cloudwatch_metric_alarms = local.cloudwatch_metric_alarms.web
        config = merge(local.ec2_autoscaling_groups.web.config, {
          ami_name = "nomis_rhel_6_10_weblogic_appserver_10_3_release_2023-03-15T17-18-22.178Z"
          instance_profile_policies = concat(local.ec2_autoscaling_groups.web.config.instance_profile_policies, [
            "Ec2T3WeblogicPolicy",
          ])
        })
        user_data_cloud_init = merge(local.ec2_autoscaling_groups.web.user_data_cloud_init, {
          args = merge(local.ec2_autoscaling_groups.web.user_data_cloud_init.args, {
            branch = "main"
          })
        })
        tags = merge(local.ec2_autoscaling_groups.web.tags, {
          nomis-environment    = "t3"
          oracle-db-hostname-a = "t3nomis-a.test.nomis.service.justice.gov.uk"
          oracle-db-hostname-b = "t3nomis-b.test.nomis.service.justice.gov.uk"
          oracle-db-name       = "T3CNOM"
        })
      })

      # ACTIVE (green deployment)
      t3-nomis-web-b = merge(local.ec2_autoscaling_groups.web, {
        autoscaling_group = merge(local.ec2_autoscaling_groups.web.autoscaling_group, {
          desired_capacity = 1
        })
        cloudwatch_metric_alarms = local.cloudwatch_metric_alarms.web
        config = merge(local.ec2_autoscaling_groups.web.config, {
          ami_name = "nomis_rhel_6_10_weblogic_appserver_10_3_release_2023-03-15T17-18-22.178Z"
          instance_profile_policies = concat(local.ec2_autoscaling_groups.web.config.instance_profile_policies, [
            "Ec2T3WeblogicPolicy",
          ])
        })
        user_data_cloud_init = merge(local.ec2_autoscaling_groups.web.user_data_cloud_init, {
          args = merge(local.ec2_autoscaling_groups.web.user_data_cloud_init.args, {
            branch = "main"
          })
        })
        tags = merge(local.ec2_autoscaling_groups.web.tags, {
          nomis-environment    = "t3"
          oracle-db-hostname-a = "t3nomis-a.test.nomis.service.justice.gov.uk"
          oracle-db-hostname-b = "t3nomis-b.test.nomis.service.justice.gov.uk"
          oracle-db-name       = "T3CNOM"
        })
      })

      test-nomis-client-a = merge(local.ec2_autoscaling_groups.client, {
        autoscaling_group = merge(local.ec2_autoscaling_groups.client.autoscaling_group, {
          desired_capacity = 3 # until we get some RD Licences
          max_size         = 3
        })
        tags = merge(local.ec2_autoscaling_groups.client.tags, {
          domain-name = "azure.noms.root"
        })
      })
    }

    ec2_instances = {
      t1-nomis-db-1-a = merge(local.ec2_instances.db, {
        cloudwatch_metric_alarms = merge(
          local.cloudwatch_metric_alarms.db,
          local.cloudwatch_metric_alarms.db_connected,
          local.cloudwatch_metric_alarms.db_backup,
        )
        config = merge(local.ec2_instances.db.config, {
          ami_name          = "nomis_rhel_7_9_oracledb_11_2_release_2023-06-23T16-28-48.100Z"
          availability_zone = "eu-west-2a"
          instance_profile_policies = concat(local.ec2_instances.db.config.instance_profile_policies, [
            "Ec2T1DatabasePolicy",
          ])
        })
        ebs_volumes = merge(local.ec2_instances.db.ebs_volumes, {
          "/dev/sdb" = { label = "app", size = 100 }
          "/dev/sdc" = { label = "app", size = 100 }
        })
        ebs_volume_config = merge(local.ec2_instances.db.ebs_volume_config, {
          data  = { total_size = 500 }
          flash = { total_size = 50 }
        })
        instance = merge(local.ec2_instances.db.instance, {
          disable_api_termination = true
        })
        tags = merge(local.ec2_instances.db.tags, {
          description         = "T1 NOMIS database"
          instance-scheduling = "skip-scheduling"
          nomis-environment   = "t1"
          oracle-sids         = "T1CNOM T1NDH T1TRDAT T1ORSYS"
        })
      })

      t1-nomis-db-1-b = merge(local.ec2_instances.db, {
        config = merge(local.ec2_instances.db.config, {
          ami_name          = "nomis_rhel_7_9_oracledb_11_2_release_2023-07-02T00-00-39.521Z"
          availability_zone = "eu-west-2b"
          instance_profile_policies = concat(local.ec2_instances.db.config.instance_profile_policies, [
            "Ec2T1DatabasePolicy",
          ])
        })
        ebs_volumes = merge(local.ec2_instances.db.ebs_volumes, {
          "/dev/sdb" = { label = "app", size = 100 }
          "/dev/sdc" = { label = "app", size = 100 }
        })
        ebs_volume_config = merge(local.ec2_instances.db.ebs_volume_config, {
          data  = { total_size = 700 }
          flash = { total_size = 50 }
        })
        instance = merge(local.ec2_instances.db.instance, {
          disable_api_termination = true
        })
        tags = merge(local.ec2_instances.db.tags, {
          description         = "for testing oracle19c upgrade"
          instance-scheduling = "skip-scheduling"
          nomis-environment   = "t1"
          oracle-sids         = ""
        })
      })

      t1-nomis-db19c-1-a = merge(local.ec2_instances.db19c, {
        cloudwatch_metric_alarms = {}
        config = merge(local.ec2_instances.db19c.config, {
          availability_zone = "eu-west-2a"
          instance_profile_policies = concat(local.ec2_instances.db19c.config.instance_profile_policies, [
            "Ec2T1DatabasePolicy",
          ])
        })
        ebs_volumes = merge(local.ec2_instances.db19c.ebs_volumes, {
          "/dev/sdb" = { label = "app", size = 100 }
          "/dev/sdc" = { label = "app", size = 100 }
        })
        ebs_volume_config = merge(local.ec2_instances.db19c.ebs_volume_config, {
          data  = { total_size = 500 }
          flash = { total_size = 150 }
        })
        instance = merge(local.ec2_instances.db19c.instance, {
          disable_api_termination = false
        })
        user_data_cloud_init = merge(local.ec2_instances.db19c.user_data_cloud_init, {
          args = merge(local.ec2_instances.db19c.user_data_cloud_init.args, {
            branch = "main"
          })
        })
        tags = merge(local.ec2_instances.db19c.tags, {
          description         = "T1 NOMIS database 19c"
          instance-scheduling = "skip-scheduling"
          nomis-environment   = "t1"
          oracle-sids         = ""
        })
      })

      t1-nomis-db19c-1-b = merge(local.ec2_instances.db19c, {
        cloudwatch_metric_alarms = {}
        config = merge(local.ec2_instances.db19c.config, {
          availability_zone = "eu-west-2b"
          instance_profile_policies = concat(local.ec2_instances.db19c.config.instance_profile_policies, [
            "Ec2T1DatabasePolicy",
          ])
        })
        ebs_volumes = merge(local.ec2_instances.db19c.ebs_volumes, {
          "/dev/sdb" = { label = "app", size = 100 }
          "/dev/sdc" = { label = "app", size = 100 }
        })
        ebs_volume_config = merge(local.ec2_instances.db19c.ebs_volume_config, {
          data  = { total_size = 500 }
          flash = { total_size = 150 }
        })
        instance = merge(local.ec2_instances.db19c.instance, {
          disable_api_termination = false
        })
        user_data_cloud_init = merge(local.ec2_instances.db19c.user_data_cloud_init, {
          args = merge(local.ec2_instances.db19c.user_data_cloud_init.args, {
            branch = "main"
          })
        })
        tags = merge(local.ec2_instances.db19c.tags, {
          description         = "T1 NOMIS database 19c"
          instance-scheduling = "skip-scheduling"
          nomis-environment   = "t1"
          oracle-sids         = ""
        })
      })

      t1-nomis-db-2-a = merge(local.ec2_instances.db, {
        cloudwatch_metric_alarms = merge(
          local.cloudwatch_metric_alarms.db,
          local.cloudwatch_metric_alarms.db_connected,
          local.cloudwatch_metric_alarms.db_backup,
          # local.cloudwatch_metric_alarms.db_misload, # disabling as only called on adhoc basis
        )
        config = merge(local.ec2_instances.db.config, {
          ami_name          = "nomis_rhel_7_9_oracledb_11_2_release_2023-06-23T16-28-48.100Z"
          availability_zone = "eu-west-2a"
          instance_profile_policies = concat(local.ec2_instances.db.config.instance_profile_policies, [
            "Ec2T1DatabasePolicy",
          ])
        })
        ebs_volumes = merge(local.ec2_instances.db.ebs_volumes, {
          "/dev/sdb" = { label = "app", size = 100 }
          "/dev/sdc" = { label = "app", size = 100 }
        })
        ebs_volume_config = merge(local.ec2_instances.db.ebs_volume_config, {
          data  = { total_size = 700 }
          flash = { total_size = 50 }
        })
        instance = merge(local.ec2_instances.db.instance, {
          disable_api_termination = true
        })
        tags = merge(local.ec2_instances.db.tags, {
          description         = "T1 NOMIS Audit and MIS database"
          instance-scheduling = "skip-scheduling"
          misload-dbname      = "T1MIS"
          nomis-environment   = "t1"
          oracle-sids         = "T1MIS T1CNMAUD"
        })
      })

      t1-nomis-xtag-a = merge(local.ec2_instances.xtag, {
        cloudwatch_metric_alarms = local.cloudwatch_metric_alarms.xtag_t1_t2
        config = merge(local.ec2_instances.xtag.config, {
          ami_name          = "nomis_rhel_7_9_weblogic_xtag_10_3_release_2023-12-21T17-09-11.541Z"
          availability_zone = "eu-west-2a"
          instance_profile_policies = concat(local.ec2_instances.xtag.config.instance_profile_policies, [
            "Ec2T1WeblogicPolicy",
          ])
        })
        user_data_cloud_init = merge(local.ec2_instances.xtag.user_data_cloud_init, {
          args = merge(local.ec2_instances.xtag.user_data_cloud_init.args, {
            branch = "main"
          })
        })
        tags = merge(local.ec2_instances.xtag.tags, {
          ndh-ems-hostname     = "t1-ems.test.ndh.nomis.service.justice.gov.uk"
          nomis-environment    = "t1"
          oracle-db-hostname-a = "t1nomis-a.test.nomis.service.justice.gov.uk"
          oracle-db-hostname-b = "t1nomis-b.test.nomis.service.justice.gov.uk"
          oracle-db-name       = "T1CNOM"
        })
      })

      t2-nomis-db-1-a = merge(local.ec2_instances.db, {
        cloudwatch_metric_alarms = merge(
          local.cloudwatch_metric_alarms.db,
          local.cloudwatch_metric_alarms.db_connected,
          local.cloudwatch_metric_alarms.db_backup,
        )
        config = merge(local.ec2_instances.db.config, {
          ami_name          = "nomis_rhel_7_9_oracledb_11_2_release_2023-06-23T16-28-48.100Z"
          availability_zone = "eu-west-2a"
          instance_profile_policies = concat(local.ec2_instances.db.config.instance_profile_policies, [
            "Ec2T2DatabasePolicy",
          ])
        })
        ebs_volumes = merge(local.ec2_instances.db.ebs_volumes, {
          "/dev/sdb" = { label = "app", size = 100 }
          "/dev/sdc" = { label = "app", size = 100 }
        })
        ebs_volume_config = merge(local.ec2_instances.db.ebs_volume_config, {
          data  = { total_size = 500 }
          flash = { total_size = 50 }
        })
        instance = merge(local.ec2_instances.db.instance, {
          disable_api_termination = true
        })
        tags = merge(local.ec2_instances.db.tags, {
          description         = "T2 NOMIS database"
          instance-scheduling = "skip-scheduling"
          nomis-environment   = "t2"
          oracle-sids         = "T2CNOM T2NDH T2TRDAT"
        })
      })

      t2-nomis-xtag-a = merge(local.ec2_instances.xtag, {
        cloudwatch_metric_alarms = local.cloudwatch_metric_alarms.xtag_t1_t2
        config = merge(local.ec2_instances.xtag.config, {
          ami_name          = "nomis_rhel_7_9_weblogic_xtag_10_3_release_2023-12-21T17-09-11.541Z"
          availability_zone = "eu-west-2a"
          instance_profile_policies = concat(local.ec2_instances.xtag.config.instance_profile_policies, [
            "Ec2T2WeblogicPolicy",
          ])
        })
        user_data_cloud_init = merge(local.ec2_instances.xtag.user_data_cloud_init, {
          args = merge(local.ec2_instances.xtag.user_data_cloud_init.args, {
            branch = "main"
          })
        })
        tags = merge(local.ec2_instances.xtag.tags, {
          ndh-ems-hostname     = "t2-ems.test.ndh.nomis.service.justice.gov.uk"
          nomis-environment    = "t2"
          oracle-db-hostname-a = "t2nomis-a.test.nomis.service.justice.gov.uk"
          oracle-db-hostname-b = "t2nomis-b.test.nomis.service.justice.gov.uk"
          oracle-db-name       = "T2CNOM"
        })
      })

      t3-nomis-db-1 = merge(local.ec2_instances.db, {
        cloudwatch_metric_alarms = merge(
          local.cloudwatch_metric_alarms.db,
          local.cloudwatch_metric_alarms.db_connected,
          local.cloudwatch_metric_alarms.db_backup,
        )
        config = merge(local.ec2_instances.db.config, {
          availability_zone = "eu-west-2a"
          instance_profile_policies = concat(local.ec2_instances.db.config.instance_profile_policies, [
            "Ec2T3DatabasePolicy",
          ])
        })
        ebs_volumes = merge(local.ec2_instances.db.ebs_volumes, {
          "/dev/sdb" = { label = "app", size = 100 }
          "/dev/sdc" = { label = "app", size = 500 }
        })
        ebs_volume_config = merge(local.ec2_instances.db.ebs_volume_config, {
          data  = { total_size = 2500 }
          flash = { total_size = 500 }
        })
        instance = merge(local.ec2_instances.db.instance, {
          disable_api_termination = true
        })
        tags = merge(local.ec2_instances.db.tags, {
          description         = "T3 NOMIS database to replace Azure T3PDL0070"
          instance-scheduling = "skip-scheduling"
          nomis-environment   = "t3"
          oracle-sids         = "T3CNOM"
          update-ssm-agent    = "patchgroup2"
        })
      })
    }

    iam_policies = {
      Ec2T1DatabasePolicy = {
        description = "Permissions required for T1 Database EC2s"
        statements = [
          {
            effect = "Allow"
            actions = [
              "secretsmanager:GetSecretValue",
              "secretsmanager:PutSecretValue",
            ]
            resources = [
              "arn:aws:secretsmanager:*:*:secret:/oracle/database/T1*/*",
            ]
          }
        ]
      }
      Ec2T2DatabasePolicy = {
        description = "Permissions required for T2 Database EC2s"
        statements = [
          {
            effect = "Allow"
            actions = [
              "secretsmanager:GetSecretValue",
              "secretsmanager:PutSecretValue",
            ]
            resources = [
              "arn:aws:secretsmanager:*:*:secret:/oracle/database/T2*/*",
            ]
          }
        ]
      }
      Ec2T3DatabasePolicy = {
        description = "Permissions required for T3 Database EC2s"
        statements = [
          {
            effect = "Allow"
            actions = [
              "secretsmanager:GetSecretValue",
              "secretsmanager:PutSecretValue",
            ]
            resources = [
              "arn:aws:secretsmanager:*:*:secret:/oracle/database/T3*/*",
            ]
          }
        ]
      }
      Ec2T1WeblogicPolicy = {
        description = "Permissions required for T1 Weblogic EC2s"
        statements = concat(local.iam_policy_statements_ec2.web, [
          {
            effect = "Allow"
            actions = [
              "secretsmanager:GetSecretValue",
              "secretsmanager:PutSecretValue",
            ]
            resources = [
              "arn:aws:secretsmanager:*:*:secret:/oracle/weblogic/t1/*",
              "arn:aws:secretsmanager:*:*:secret:/oracle/database/T1*/weblogic-*",
            ]
          }
        ])
      }
      Ec2T2WeblogicPolicy = {
        description = "Permissions required for T2 Weblogic EC2s"
        statements = concat(local.iam_policy_statements_ec2.web, [
          {
            effect = "Allow"
            actions = [
              "secretsmanager:GetSecretValue",
              "secretsmanager:PutSecretValue",
            ]
            resources = [
              "arn:aws:secretsmanager:*:*:secret:/oracle/weblogic/t2/*",
              "arn:aws:secretsmanager:*:*:secret:/oracle/database/T2*/weblogic-*",
            ]
          }
        ])
      }
      Ec2T3WeblogicPolicy = {
        description = "Permissions required for T3 Weblogic EC2s"
        statements = concat(local.iam_policy_statements_ec2.web, [
          {
            effect = "Allow"
            actions = [
              "secretsmanager:GetSecretValue",
              "secretsmanager:PutSecretValue",
            ]
            resources = [
              "arn:aws:secretsmanager:*:*:secret:/oracle/weblogic/t3/*",
              "arn:aws:secretsmanager:*:*:secret:/oracle/database/T3*/weblogic-*",
            ]
          }
        ])
      }
    }

    lbs = {
      private = merge(local.lbs.private, {

        listeners = merge(local.lbs.private.listeners, {
          https = merge(local.lbs.private.listeners.https, {
            alarm_target_group_names  = [] # don't enable as environments are powered up/down frequently
            certificate_names_or_arns = ["nomis_wildcard_cert_v3"]

            # /home/oracle/admin/scripts/lb_maintenance_mode.sh script on
            # weblogic servers can alter priorities to enable maintenance message
            rules = {
              t1-nomis-web-a-http-7777 = {
                priority = 1300 # reduce by 1000 to make active
                actions = [{
                  type              = "forward"
                  target_group_name = "t1-nomis-web-a-http-7777"
                }]
                conditions = [{
                  host_header = {
                    values = [
                      "t1-nomis-web-a.test.nomis.service.justice.gov.uk",
                    ]
                  }
                }]
              }
              t1-nomis-web-b-http-7777 = {
                priority = 1450 # reduce by 1000 to make active
                actions = [{
                  type              = "forward"
                  target_group_name = "t1-nomis-web-b-http-7777"
                }]
                conditions = [{
                  host_header = {
                    values = [
                      "t1-nomis-web-b.test.nomis.service.justice.gov.uk",
                      "c-t1.test.nomis.service.justice.gov.uk",
                    ]
                  }
                }]
              }
              t2-nomis-web-a-http-7777 = {
                priority = 1550
                actions = [{
                  type              = "forward"
                  target_group_name = "t2-nomis-web-a-http-7777"
                }]
                conditions = [{
                  host_header = {
                    values = [
                      "t2-nomis-web-a.test.nomis.service.justice.gov.uk",
                    ]
                  }
                }]
              }
              t2-nomis-web-b-http-7777 = {
                priority = 1600
                actions = [{
                  type              = "forward"
                  target_group_name = "t2-nomis-web-b-http-7777"
                }]
                conditions = [{
                  host_header = {
                    values = [
                      "t2-nomis-web-b.test.nomis.service.justice.gov.uk",
                      "c-t2.test.nomis.service.justice.gov.uk",
                    ]
                  }
                }]
              }
              t3-nomis-web-a-http-7777 = {
                priority = 700
                actions = [{
                  type              = "forward"
                  target_group_name = "t3-nomis-web-a-http-7777"
                }]
                conditions = [{
                  host_header = {
                    values = [
                      "t3-nomis-web-a.test.nomis.service.justice.gov.uk",
                    ]
                  }
                }]
              }
              t3-nomis-web-b-http-7777 = {
                priority = 800
                actions = [{
                  type              = "forward"
                  target_group_name = "t3-nomis-web-b-http-7777"
                }]
                conditions = [{
                  host_header = {
                    values = [
                      "t3-nomis-web-b.test.nomis.service.justice.gov.uk",
                      "c-t3.test.nomis.service.justice.gov.uk",
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
                    message_body = templatefile("templates/maintenance.html.tftpl", local.lb_maintenance_message_test)
                    status_code  = "200"
                  }
                }]
                conditions = [{
                  host_header = {
                    values = [
                      "maintenance.test.nomis.service.justice.gov.uk",
                      "c-t1.test.nomis.service.justice.gov.uk",
                      "c-t2.test.nomis.service.justice.gov.uk",
                      "c-t3.test.nomis.service.justice.gov.uk",
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
      "test.nomis.service.justice.gov.uk" = {
        records = [
          # T1
          { name = "t1nomis", type = "CNAME", ttl = "300", records = ["t1nomis-a.test.nomis.service.justice.gov.uk"] },
          { name = "t1nomis-a", type = "CNAME", ttl = "300", records = ["t1-nomis-db-1-a.nomis.hmpps-test.modernisation-platform.service.justice.gov.uk"] },
          { name = "t1nomis-b", type = "CNAME", ttl = "300", records = ["t1-nomis-db-1-a.nomis.hmpps-test.modernisation-platform.service.justice.gov.uk"] },
          { name = "t1ndh", type = "CNAME", ttl = "300", records = ["t1ndh-a.test.nomis.service.justice.gov.uk"] },
          { name = "t1ndh-a", type = "CNAME", ttl = "300", records = ["t1-nomis-db-1-a.nomis.hmpps-test.modernisation-platform.service.justice.gov.uk"] },
          { name = "t1ndh-b", type = "CNAME", ttl = "300", records = ["t1-nomis-db-1-a.nomis.hmpps-test.modernisation-platform.service.justice.gov.uk"] },
          { name = "t1or", type = "CNAME", ttl = "300", records = ["t1or-a.test.nomis.service.justice.gov.uk"] },
          { name = "t1or-a", type = "CNAME", ttl = "300", records = ["t1-nomis-db-1-a.nomis.hmpps-test.modernisation-platform.service.justice.gov.uk"] },
          { name = "t1or-b", type = "CNAME", ttl = "300", records = ["t1-nomis-db-1-a.nomis.hmpps-test.modernisation-platform.service.justice.gov.uk"] },
          { name = "t1trdat", type = "CNAME", ttl = "300", records = ["t1trdat-a.test.nomis.service.justice.gov.uk"] },
          { name = "t1trdat-a", type = "CNAME", ttl = "300", records = ["t1-nomis-db-1-a.nomis.hmpps-test.modernisation-platform.service.justice.gov.uk"] },
          { name = "t1trdat-b", type = "CNAME", ttl = "300", records = ["t1-nomis-db-1-a.nomis.hmpps-test.modernisation-platform.service.justice.gov.uk"] },
          { name = "t1audit", type = "CNAME", ttl = "300", records = ["t1audit-a.test.nomis.service.justice.gov.uk"] },
          { name = "t1audit-a", type = "CNAME", ttl = "300", records = ["t1-nomis-db-2-a.nomis.hmpps-test.modernisation-platform.service.justice.gov.uk"] },
          { name = "t1audit-b", type = "CNAME", ttl = "300", records = ["t1-nomis-db-2-a.nomis.hmpps-test.modernisation-platform.service.justice.gov.uk"] },
          { name = "t1mis", type = "CNAME", ttl = "300", records = ["t1mis-a.test.nomis.service.justice.gov.uk"] },
          { name = "t1mis-a", type = "CNAME", ttl = "300", records = ["t1-nomis-db-2-a.nomis.hmpps-test.modernisation-platform.service.justice.gov.uk"] },
          { name = "t1mis-b", type = "CNAME", ttl = "300", records = ["t1-nomis-db-2-a.nomis.hmpps-test.modernisation-platform.service.justice.gov.uk"] },
          # T2
          { name = "t2nomis", type = "CNAME", ttl = "300", records = ["t2nomis-a.test.nomis.service.justice.gov.uk"] },
          { name = "t2nomis-a", type = "CNAME", ttl = "300", records = ["t2-nomis-db-1-a.nomis.hmpps-test.modernisation-platform.service.justice.gov.uk"] },
          { name = "t2nomis-b", type = "CNAME", ttl = "300", records = ["t2-nomis-db-1-a.nomis.hmpps-test.modernisation-platform.service.justice.gov.uk"] },
          { name = "t2ndh", type = "CNAME", ttl = "300", records = ["t2ndh-a.test.nomis.service.justice.gov.uk"] },
          { name = "t2ndh-a", type = "CNAME", ttl = "300", records = ["t2-nomis-db-1-a.nomis.hmpps-test.modernisation-platform.service.justice.gov.uk"] },
          { name = "t2ndh-b", type = "CNAME", ttl = "300", records = ["t2-nomis-db-1-a.nomis.hmpps-test.modernisation-platform.service.justice.gov.uk"] },
          { name = "t2or", type = "CNAME", ttl = "300", records = ["t2or-a.test.nomis.service.justice.gov.uk"] },
          { name = "t2or-a", type = "CNAME", ttl = "300", records = ["t2-nomis-db-1-a.nomis.hmpps-test.modernisation-platform.service.justice.gov.uk"] },
          { name = "t2or-b", type = "CNAME", ttl = "300", records = ["t2-nomis-db-1-a.nomis.hmpps-test.modernisation-platform.service.justice.gov.uk"] },
          { name = "t2trdat", type = "CNAME", ttl = "300", records = ["t2trdat-a.test.nomis.service.justice.gov.uk"] },
          { name = "t2trdat-a", type = "CNAME", ttl = "300", records = ["t2-nomis-db-1-a.nomis.hmpps-test.modernisation-platform.service.justice.gov.uk"] },
          { name = "t2trdat-b", type = "CNAME", ttl = "300", records = ["t2-nomis-db-1-a.nomis.hmpps-test.modernisation-platform.service.justice.gov.uk"] },
          # T3
          { name = "t3nomis", type = "CNAME", ttl = "300", records = ["t3nomis-b.test.nomis.service.justice.gov.uk"] },
          { name = "t3nomis-a", type = "CNAME", ttl = "300", records = ["t3-nomis-db-1.nomis.hmpps-test.modernisation-platform.service.justice.gov.uk"] },
          { name = "t3nomis-b", type = "CNAME", ttl = "300", records = ["t3-nomis-db-1.nomis.hmpps-test.modernisation-platform.service.justice.gov.uk"] },
        ]
        lb_alias_records = [
          { name = "maintenance", type = "A", lbs_map_key = "private" },
          # T1
          { name = "t1-nomis-web-a", type = "A", lbs_map_key = "private" },
          { name = "t1-nomis-web-b", type = "A", lbs_map_key = "private" },
          { name = "c-t1", type = "A", lbs_map_key = "private" },
          # T2
          { name = "t2-nomis-web-a", type = "A", lbs_map_key = "private" },
          { name = "t2-nomis-web-b", type = "A", lbs_map_key = "private" },
          { name = "c-t2", type = "A", lbs_map_key = "private" },
          # T3
          { name = "t3-nomis-web-a", type = "A", lbs_map_key = "private" },
          { name = "t3-nomis-web-b", type = "A", lbs_map_key = "private" },
          { name = "c-t3", type = "A", lbs_map_key = "private" },
        ]
      }
    }

    s3_buckets = {
      nomis-audit-archives = {
        bucket_policy_v2 = [
          module.baseline_presets.s3_bucket_policies.DevelopmentReadOnlyAccessBucketPolicy
        ]
        custom_kms_key = module.environment.kms_keys["general"].arn
        iam_policies   = module.baseline_presets.s3_iam_policies
        lifecycle_rule = [module.baseline_presets.s3_lifecycle_rules.default]
        tags = {
          backup = "false"
        }
      }
    }

    secretsmanager_secrets = {
      "/oracle/weblogic/t1"       = local.secretsmanager_secrets.web
      "/oracle/weblogic/t2"       = local.secretsmanager_secrets.web
      "/oracle/weblogic/t3"       = local.secretsmanager_secrets.web
      "/oracle/database/T1CNOM"   = local.secretsmanager_secrets.db_cnom
      "/oracle/database/T1NDH"    = local.secretsmanager_secrets.db
      "/oracle/database/T1TRDAT"  = local.secretsmanager_secrets.db
      "/oracle/database/T1CNMAUD" = local.secretsmanager_secrets.db
      "/oracle/database/T1MIS"    = local.secretsmanager_secrets.db_mis
      "/oracle/database/T1ORSYS"  = local.secretsmanager_secrets.db
      "/oracle/database/T2CNOM"   = local.secretsmanager_secrets.db_cnom
      "/oracle/database/T2NDH"    = local.secretsmanager_secrets.db
      "/oracle/database/T2TRDAT"  = local.secretsmanager_secrets.db
      "/oracle/database/T3CNOM"   = local.secretsmanager_secrets.db_cnom

      "/hmpps/self-signed-certs" = {
        secrets = {
          passwords = { description = "certificate passwords" }
        }
      }
    }
  }
}
