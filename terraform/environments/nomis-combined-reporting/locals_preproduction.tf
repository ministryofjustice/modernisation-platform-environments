locals {

  baseline_presets_preproduction = {
    options = {
      sns_topics = {
        pagerduty_integrations = {
          pagerduty = "nomis-combined-reporting-preproduction"
        }
      }
    }
  }

  # please keep resources in alphabetical order
  baseline_preproduction = {

    acm_certificates = {
      nomis_combined_reporting_wildcard_cert = {
        cloudwatch_metric_alarms = module.baseline_presets.cloudwatch_metric_alarms.acm
        domain_name              = "modernisation-platform.service.justice.gov.uk"
        subject_alternate_names = [
          "preproduction.reporting.nomis.service.justice.gov.uk",
          "*.preproduction.reporting.nomis.service.justice.gov.uk",
        ]
        tags = {
          description = "Wildcard certificate for the preproduction environment"
        }
      }
    }

    ec2_autoscaling_groups = {
      pp-ncr-app = merge(local.ec2_autoscaling_groups.bip_app, {
        autoscaling_group = merge(local.ec2_autoscaling_groups.bip_app.autoscaling_group, {
          desired_capacity = 0
        })
        config = merge(local.ec2_autoscaling_groups.bip_app.config, {
          instance_profile_policies = concat(local.ec2_autoscaling_groups.bip_app.config.instance_profile_policies, [
            "Ec2PPReportingPolicy",
          ])
        })
        user_data_cloud_init = merge(local.ec2_autoscaling_groups.bip_app.user_data_cloud_init, {
          args = merge(local.ec2_autoscaling_groups.bip_app.user_data_cloud_init.args, {
            branch = "ncr/TM-503/preprod-bip-fixes"
          })
        })
        tags = merge(local.ec2_autoscaling_groups.bip_app.tags, {
          nomis-combined-reporting-environment = "pp"
        })
      })

      pp-ncr-cms = merge(local.ec2_autoscaling_groups.bip_cms, {
        autoscaling_group = merge(local.ec2_autoscaling_groups.bip_cms.autoscaling_group, {
          desired_capacity = 0
        })
        config = merge(local.ec2_autoscaling_groups.bip_cms.config, {
          instance_profile_policies = concat(local.ec2_autoscaling_groups.bip_cms.config.instance_profile_policies, [
            "Ec2PPReportingPolicy",
          ])
        })
        user_data_cloud_init = merge(local.ec2_autoscaling_groups.bip_cms.user_data_cloud_init, {
          args = merge(local.ec2_autoscaling_groups.bip_cms.user_data_cloud_init.args, {
            branch = "ncr/TM-503/preprod-bip-fixes"
          })
        })
        tags = merge(local.ec2_autoscaling_groups.bip_cms.tags, {
          nomis-combined-reporting-environment = "pp"
        })
      })

      pp-ncr-webadmin = merge(local.ec2_autoscaling_groups.bip_webadmin, {
        autoscaling_group = merge(local.ec2_autoscaling_groups.bip_webadmin.autoscaling_group, {
          desired_capacity = 0
        })
        config = merge(local.ec2_autoscaling_groups.bip_webadmin.config, {
          instance_profile_policies = concat(local.ec2_autoscaling_groups.bip_webadmin.config.instance_profile_policies, [
            "Ec2PPReportingPolicy",
          ])
        })
        user_data_cloud_init = merge(local.ec2_autoscaling_groups.bip_webadmin.user_data_cloud_init, {
          args = merge(local.ec2_autoscaling_groups.bip_webadmin.user_data_cloud_init.args, {
            branch = "ncr/TM-503/preprod-bip-fixes"
          })
        })
        tags = merge(local.ec2_autoscaling_groups.bip_webadmin.tags, {
          nomis-combined-reporting-environment = "pp"
        })
      })

      pp-ncr-web = merge(local.ec2_autoscaling_groups.bip_web, {
        autoscaling_group = merge(local.ec2_autoscaling_groups.bip_web.autoscaling_group, {
          desired_capacity = 0
        })
        config = merge(local.ec2_autoscaling_groups.bip_web.config, {
          instance_profile_policies = concat(local.ec2_autoscaling_groups.bip_web.config.instance_profile_policies, [
            "Ec2PPReportingPolicy",
          ])
        })
        user_data_cloud_init = merge(local.ec2_autoscaling_groups.bip_web.user_data_cloud_init, {
          args = merge(local.ec2_autoscaling_groups.bip_web.user_data_cloud_init.args, {
            branch = "ncr/TM-503/preprod-bip-fixes"
          })
        })
        tags = merge(local.ec2_autoscaling_groups.bip_web.tags, {
          nomis-combined-reporting-environment = "pp"
        })
      })
    }

    ec2_instances = {

      ls-ncr-db-1-a = merge(local.ec2_instances.db, {
        cloudwatch_metric_alarms = merge(
          local.cloudwatch_metric_alarms.db,
          local.cloudwatch_metric_alarms.db_connected,
          local.cloudwatch_metric_alarms.db_backup,
        )
        config = merge(local.ec2_instances.db.config, {
          availability_zone = "eu-west-2a"
          instance_profile_policies = concat(local.ec2_instances.db.config.instance_profile_policies, [
            "Ec2LSASTDatabasePolicy",
          ])
        })
        tags = merge(local.ec2_instances.db.tags, {
          description                          = "LSAST NCR DATABASE"
          nomis-combined-reporting-environment = "lsast"
          oracle-sids                          = "LSBIPSYS LSBIPAUD"
          instance-scheduling                  = "skip-scheduling"
        })
      })

      pp-ncr-cms-a = merge(local.ec2_instances.bip_app, {
        #cloudwatch_metric_alarms = local.cloudwatch_metric_alarms.bip_app # comment in when commissioned
        config = merge(local.ec2_instances.bip_app.config, {
          ami_name          = "base_rhel_8_5_2024-05-01T00-00-19.643Z"
          availability_zone = "eu-west-2a"
          instance_profile_policies = concat(local.ec2_instances.bip_app.config.instance_profile_policies, [
            "Ec2PPReportingPolicy",
          ])
        })
        instance = merge(local.ec2_instances.bip_app.instance, {
          instance_type = "m6i.xlarge",
        })
        tags = merge(local.ec2_instances.bip_app.tags, {
          description                          = "PreProd SAP BI Platform CMS installation and configurations"
          instance-scheduling                  = "skip-scheduling"
          node                                 = "1"
          nomis-combined-reporting-environment = "pp"
          type                                 = "management"
          server-type                          = "ncr-bip"
          shutdown-order                       = 3
        })
      })

      pp-ncr-cms-b = merge(local.ec2_instances.bip_app, {
        #cloudwatch_metric_alarms = local.cloudwatch_metric_alarms.bip_app # comment in when commissioned
        config = merge(local.ec2_instances.bip_app.config, {
          ami_name          = "base_rhel_8_5_2024-05-01T00-00-19.643Z"
          availability_zone = "eu-west-2b"
          instance_profile_policies = concat(local.ec2_instances.bip_app.config.instance_profile_policies, [
            "Ec2PPReportingPolicy",
          ])
        })
        instance = merge(local.ec2_instances.bip_app.instance, {
          instance_type = "m6i.xlarge",
        })
        tags = merge(local.ec2_instances.bip_app.tags, {
          description                          = "PreProd SAP BI Platform CMS installation and configurations"
          instance-scheduling                  = "skip-scheduling"
          node                                 = "2"
          nomis-combined-reporting-environment = "pp"
          server-type                          = "ncr-bip"
          type                                 = "management"
          shutdown-order                       = 2
        })
      })

      pp-ncr-db-1-a = merge(local.ec2_instances.db, {
        cloudwatch_metric_alarms = merge(
          local.cloudwatch_metric_alarms.db,
          local.cloudwatch_metric_alarms.db_connected,
          local.cloudwatch_metric_alarms.db_backup,
        )
        config = merge(local.ec2_instances.db.config, {
          availability_zone = "eu-west-2a"
          instance_profile_policies = concat(local.ec2_instances.db.config.instance_profile_policies, [
            "Ec2PPDatabasePolicy",
          ])
        })
        tags = merge(local.ec2_instances.db.tags, {
          description                          = "PREPROD NCR DATABASE"
          nomis-combined-reporting-environment = "pp"
          oracle-sids                          = "PPBIPSYS PPBIPAUD"
          instance-scheduling                  = "skip-scheduling"
        })
      })

      pp-ncr-client-a = merge(local.ec2_autoscaling_groups.jumpserver, {
        # cloudwatch_metric_alarms = local.client_cloudwatch_metric_alarms # comment in when commissioned
        config = merge(local.ec2_autoscaling_groups.jumpserver.config, {
          ami_name          = "hmpps_windows_server_2019_release_2024-05-02T00-00-37.552Z"
          availability_zone = "eu-west-2a"
          instance_profile_policies = concat(local.ec2_autoscaling_groups.jumpserver.config.instance_profile_policies, [
            "Ec2PPReportingPolicy",
          ])
        })
        instance = merge(local.ec2_autoscaling_groups.jumpserver.instance, {
          instance_type = "t3.large",
        })
        tags = merge(local.ec2_autoscaling_groups.jumpserver.tags, {
          description                          = "PreProd Jumpserver and Client Tools"
          instance-scheduling                  = "skip-scheduling"
          nomis-combined-reporting-environment = "pp"
        })
      })

      pp-ncr-etl-a = merge(local.ec2_instances.bods, {
        # cloudwatch_metric_alarms = local.cloudwatch_metric_alarms.bods # comment in when commissioned
        config = merge(local.ec2_instances.bods.config, {
          ami_name          = "hmpps_windows_server_2019_release_2024-05-02T00-00-37.552Z"
          availability_zone = "eu-west-2a"
          instance_profile_policies = concat(local.ec2_instances.bods.config.instance_profile_policies, [
            "Ec2PPReportingPolicy",
          ])
        })
        instance = merge(local.ec2_instances.bods.instance, {
          instance_type = "m6i.2xlarge",
        })
        tags = merge(local.ec2_instances.bods.tags, {
          description                          = "PreProd SAP BI Platform ETL installation and configurations"
          instance-scheduling                  = "skip-scheduling"
          nomis-combined-reporting-environment = "pp"
        })
      })

      pp-ncr-processing-1-a = merge(local.ec2_instances.bip_app, {
        # cloudwatch_metric_alarms = local.cloudwatch_metric_alarms.bip_app # comment in when commissioned
        config = merge(local.ec2_instances.bip_app.config, {
          ami_name          = "base_rhel_8_5_2024-05-01T00-00-19.643Z"
          availability_zone = "eu-west-2a"
          instance_profile_policies = concat(local.ec2_instances.bip_app.config.instance_profile_policies, [
            "Ec2PPReportingPolicy",
          ])
        })
        instance = merge(local.ec2_instances.bip_app.instance, {
          instance_type = "m6i.4xlarge",
        })
        tags = merge(local.ec2_instances.bip_app.tags, {
          description                          = "PreProd SAP BI Platform installation and configurations"
          instance-scheduling                  = "skip-scheduling"
          node                                 = "3"
          nomis-combined-reporting-environment = "pp"
          server-type                          = "ncr-bip"
          type                                 = "processing"
          shutdown-order                       = 1
        })
      })

      pp-ncr-web-1-a = merge(local.ec2_instances.bip_web, {
        # cloudwatch_metric_alarms = local.cloudwatch_metric_alarms.bip_web # comment in when commissioned
        config = merge(local.ec2_instances.bip_web.config, {
          ami_name          = "base_rhel_8_5_2024-05-01T00-00-19.643Z"
          availability_zone = "eu-west-2a"
          instance_profile_policies = concat(local.ec2_instances.bip_web.config.instance_profile_policies, [
            "Ec2PPReportingPolicy",
          ])
        })
        instance = merge(local.ec2_instances.bip_web.instance, {
          instance_type = "r6i.xlarge",
        })
        tags = merge(local.ec2_instances.bip_web.tags, {
          description                          = "PreProd SAP BI Platform web-tier installation and configurations"
          instance-scheduling                  = "skip-scheduling"
          nomis-combined-reporting-environment = "pp"
          shutdown-order                       = 4
        })
      })

      pp-ncr-web-2-b = merge(local.ec2_instances.bip_web, {
        # cloudwatch_metric_alarms = local.cloudwatch_metric_alarms.bip_web # comment in when commissioned
        config = merge(local.ec2_instances.bip_web.config, {
          ami_name          = "base_rhel_8_5_2024-05-01T00-00-19.643Z"
          availability_zone = "eu-west-2b"
          instance_profile_policies = concat(local.ec2_instances.bip_web.config.instance_profile_policies, [
            "Ec2PPReportingPolicy",
          ])
        })
        instance = merge(local.ec2_instances.bip_web.instance, {
          instance_type = "r6i.xlarge",
        })
        tags = merge(local.ec2_instances.bip_web.tags, {
          description                          = "PreProd SAP BI Platform web-tier installation and configurations"
          instance-scheduling                  = "skip-scheduling"
          nomis-combined-reporting-environment = "pp"
          shutdown-order                       = 4
        })
      })

      pp-ncr-web-admin-a = merge(local.ec2_instances.bip_web, {
        # cloudwatch_metric_alarms = local.cloudwatch_metric_alarms.bip_web # comment in when commissioned
        config = merge(local.ec2_instances.bip_web.config, {
          ami_name          = "base_rhel_8_5_2024-05-01T00-00-19.643Z"
          availability_zone = "eu-west-2a"
          instance_profile_policies = concat(local.ec2_instances.bip_web.config.instance_profile_policies, [
            "Ec2PPReportingPolicy",
          ])
        })
        instance = merge(local.ec2_instances.bip_web.instance, {
          instance_type = "r6i.large",
        })
        tags = merge(local.ec2_instances.bip_web.tags, {
          description                          = "PreProd SAP BI Platform web-tier admin installation and configurations"
          instance-scheduling                  = "skip-scheduling"
          nomis-combined-reporting-environment = "pp"
        })
      })
    }

    efs = {
      pp-ncr-sap-share = local.efs.sap_share
    }

    iam_policies = {
      Ec2LSASTDatabasePolicy = {
        description = "Permissions required for LSAST Database EC2s"
        statements = [
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

      Ec2LSASTReportingPolicy = {
        description = "Permissions required for LSAST reporting EC2s"
        statements = [
          {
            effect = "Allow"
            actions = [
              "secretsmanager:GetSecretValue",
              "secretsmanager:PutSecretValue",
            ]
            resources = [
              "arn:aws:secretsmanager:*:*:secret:/ec2/ncr-bip/lsast/*",
              "arn:aws:secretsmanager:*:*:secret:/ec2/ncr-web/lsast/*",
            ]
          }
        ]
      }

      Ec2PPDatabasePolicy = {
        description = "Permissions required for PREPROD Database EC2s"
        statements = [
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

      Ec2PPReportingPolicy = {
        description = "Permissions required for PP reporting EC2s"
        statements = [
          {
            effect = "Allow"
            actions = [
              "secretsmanager:GetSecretValue",
              "secretsmanager:PutSecretValue",
            ]
            resources = [
              "arn:aws:secretsmanager:*:*:secret:/ec2/ncr-bip/pp/*",
              "arn:aws:secretsmanager:*:*:secret:/ec2/ncr-web/pp/*",
            ]
          }
        ]
      }
    }

    lbs = {
      private = merge(local.lbs.private, {

        instance_target_groups = {
          pp-ncr-web = merge(local.lbs.private.instance_target_groups.web, {
            attachments = [
              { ec2_instance_name = "pp-ncr-web-1-a" },
              { ec2_instance_name = "pp-ncr-web-2-b" },
            ]
          })
        }
        listeners = merge(local.lbs.private.listeners, {
          https = merge(local.lbs.private.listeners.https, {
            certificate_names_or_arns = ["nomis_combined_reporting_wildcard_cert"]

            rules = {
              pp-ncr-web = {
                priority = 4580
                actions = [{
                  type              = "forward"
                  target_group_name = "pp-ncr-web"
                }]
                conditions = [{
                  host_header = {
                    values = [
                      "preproduction.reporting.nomis.service.justice.gov.uk"
                    ]
                  }
                }]
              }
            }
          })
        })
      })

      public = merge(local.lbs.public, {
        listeners = merge(local.lbs.public.listeners, {
          https = merge(local.lbs.public.listeners.https, {
            alarm_target_group_names = []
            rules = {
              webadmin = {
                priority = 100
                actions = [{
                  type              = "forward"
                  target_group_name = "pp-ncr-webadmin-http-7010"
                }]
                conditions = [{
                  host_header = {
                    values = [
                      "webadmin.preproduction.reporting.nomis.service.justice.gov.uk",
                    ]
                  }
                }]
              }
              web = {
                priority = 200
                actions = [{
                  type              = "forward"
                  target_group_name = "pp-ncr-web-http-7777"
                }]
                conditions = [{
                  host_header = {
                    values = [
                      "web.preproduction.reporting.nomis.service.justice.gov.uk",
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
      "lsast.reporting.nomis.service.justice.gov.uk" = {
        records = [
          { name = "db", type = "CNAME", ttl = "3600", records = ["ls-ncr-db-1-a.nomis-combined-reporting.hmpps-preproduction.modernisation-platform.service.justice.gov.uk"] },
        ]
      }

      "preproduction.reporting.nomis.service.justice.gov.uk" = {
        records = [
          { name = "db", type = "CNAME", ttl = "3600", records = ["pp-ncr-db-1-a.nomis-combined-reporting.hmpps-preproduction.modernisation-platform.service.justice.gov.uk"] },
          { name = "admin", type = "CNAME", ttl = "3600", records = ["pp-ncr-web-admin-a.nomis-combined-reporting.hmpps-preproduction.modernisation-platform.service.justice.gov.uk"] },
        ]
        lb_alias_records = [
          { name = "", type = "A", lbs_map_key = "private" },
          { name = "webadmin", type = "A", lbs_map_key = "public" },
          { name = "web", type = "A", lbs_map_key = "private" },
        ]
      }
    }

    secretsmanager_secrets = {
      "/ec2/ncr-bip/pp"           = local.secretsmanager_secrets.bip_app
      "/ec2/ncr-web/pp"           = local.secretsmanager_secrets.bip_web
      "/ec2/ncr-bip/lsast"        = local.secretsmanager_secrets.bip_app
      "/ec2/ncr-web/lsast"        = local.secretsmanager_secrets.bip_web
      "/oracle/database/PPBIPSYS" = local.secretsmanager_secrets.db
      "/oracle/database/PPBIPAUD" = local.secretsmanager_secrets.db
      "/oracle/database/PPBISYS"  = local.secretsmanager_secrets.db
      "/oracle/database/PPBIAUD"  = local.secretsmanager_secrets.db
      "/oracle/database/LSBIPSYS" = local.secretsmanager_secrets.db
      "/oracle/database/LSBIPAUD" = local.secretsmanager_secrets.db
      "/oracle/database/LSBISYS"  = local.secretsmanager_secrets.db
      "/oracle/database/LSBIAUD"  = local.secretsmanager_secrets.db
    }
  }
}
