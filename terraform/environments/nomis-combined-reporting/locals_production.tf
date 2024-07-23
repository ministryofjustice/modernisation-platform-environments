locals {

  baseline_presets_production = {
    options = {
      sns_topics = {
        pagerduty_integrations = {
          dso_pagerduty               = "nomis_alarms"
          dba_pagerduty               = "hmpps_shef_dba_low_priority"
          dba_high_priority_pagerduty = "hmpps_shef_dba_high_priority"
        }
      }
    }
  }

  # please keep resources in alphabetical order
  baseline_production = {

    acm_certificates = {
      nomis_combined_reporting_wildcard_cert = {
        cloudwatch_metric_alarms = module.baseline_presets.cloudwatch_metric_alarms.acm
        domain_name              = "modernisation-platform.service.justice.gov.uk"
        subject_alternate_names = [
          "reporting.nomis.service.justice.gov.uk",
          "*.reporting.nomis.service.justice.gov.uk",
        ]
        tags = {
          description = "Wildcard certificate for the production environment"
        }
      }
    }

    ec2_instances = {

      # Comment out till needed for deployment
      pd-ncr-cms-a = merge(local.ec2_instances.bip_app, {
        #cloudwatch_metric_alarms = local.cloudwatch_metric_alarms.bip_app # comment in when commissioned
        config = merge(local.ec2_instances.bip_app.config, {
          ami_name          = "base_rhel_8_5_2024-05-01T00-00-19.643Z"
          availability_zone = "eu-west-2a"
          instance_profile_policies = concat(local.ec2_instances.bip_app.config.instance_profile_policies, [
            "Ec2PDReportingPolicy",
          ])
        })
        instance = merge(local.ec2_instances.bip_app.instance, {
          instance_type = "m6i.xlarge",
        })
        tags = merge(local.ec2_instances.bip_app.tags, {
          description                          = "Prod SAP BI Platform CMS installation and configurations"
          instance-scheduling                  = "skip-scheduling"
          node                                 = "1"
          nomis-combined-reporting-environment = "pd"
          type                                 = "management"
        })
      })

      pd-ncr-cms-b = merge(local.ec2_instances.bip_app, {
        #cloudwatch_metric_alarms = local.cloudwatch_metric_alarms.bip_app # comment in when commissioned
        config = merge(local.ec2_instances.bip_app.config, {
          ami_name          = "base_rhel_8_5_2024-05-01T00-00-19.643Z"
          availability_zone = "eu-west-2b"
          instance_profile_policies = concat(local.ec2_instances.bip_app.config.instance_profile_policies, [
            "Ec2PDReportingPolicy",
          ])
        })
        instance = merge(local.ec2_instances.bip_app.instance, {
          instance_type = "m6i.xlarge",
        })
        tags = merge(local.ec2_instances.bip_app.tags, {
          description                          = "Prod SAP BI Platform CMS installation and configurations"
          instance-scheduling                  = "skip-scheduling"
          node                                 = "2"
          nomis-combined-reporting-environment = "pd"
          type                                 = "management"
        })
      })

      pd-ncr-db-1-a = merge(local.ec2_instances.db, {
        cloudwatch_metric_alarms = merge(
          local.cloudwatch_metric_alarms.db,
          local.cloudwatch_metric_alarms.db_connected,
          local.cloudwatch_metric_alarms.db_backup,
        )
        config = merge(local.ec2_instances.db.config, {
          availability_zone = "eu-west-2a"
          instance_profile_policies = concat(local.ec2_instances.db.config.instance_profile_policies, [
            "Ec2PDDatabasePolicy",
          ])
        })
        tags = merge(local.ec2_instances.db.tags, {
          description                          = "PROD NCR DATABASE"
          nomis-combined-reporting-environment = "pd"
          oracle-sids                          = "PDBIPSYS PDBIPAUD"
          instance-scheduling                  = "skip-scheduling"
        })
      })

      pd-ncr-db-1-b = merge(local.ec2_instances.db, {
        # TODO: comment in when commissioned
        # cloudwatch_metric_alarms = merge(
        #   local.cloudwatch_metric_alarms.db,
        #   local.cloudwatch_metric_alarms.db_connected,
        # )
        config = merge(local.ec2_instances.db.config, {
          availability_zone = "eu-west-2b"
          instance_profile_policies = concat(local.ec2_instances.db.config.instance_profile_policies, [
            "Ec2PDDatabasePolicy",
          ])
        })
        tags = merge(local.ec2_instances.db.tags, {
          description                          = "PROD NCR DATABASE"
          nomis-combined-reporting-environment = "pd"
          oracle-sids                          = ""
          instance-scheduling                  = "skip-scheduling"
        })
      })

      # Comment out till needed for deployment
      pd-ncr-client-a = merge(local.ec2_autoscaling_groups.jumpserver, {
        # cloudwatch_metric_alarms = local.client_cloudwatch_metric_alarms # comment in when commissioned
        config = merge(local.ec2_autoscaling_groups.jumpserver.config, {
          ami_name          = "hmpps_windows_server_2019_release_2024-05-02T00-00-37.552Z"
          availability_zone = "eu-west-2a"
          instance_profile_policies = concat(local.ec2_autoscaling_groups.jumpserver.config.instance_profile_policies, [
            "Ec2PDReportingPolicy",
          ])
        })
        instance = merge(local.ec2_autoscaling_groups.jumpserver.instance, {
          instance_type = "t3.large",
        })
        tags = merge(local.ec2_autoscaling_groups.jumpserver.tags, {
          description                          = "Prod Jumpserver and Client Tools"
          instance-scheduling                  = "skip-scheduling"
          nomis-combined-reporting-environment = "pd"
        })
      })

      # Comment out till needed for deployment
      pd-ncr-etl-1-a = merge(local.ec2_instances.bods, {
        # cloudwatch_metric_alarms = local.cloudwatch_metric_alarms.bods # comment in when commissioned
        config = merge(local.ec2_instances.bods.config, {
          ami_name          = "hmpps_windows_server_2019_release_2024-05-02T00-00-37.552Z"
          availability_zone = "eu-west-2a"
          instance_profile_policies = concat(local.ec2_instances.bods.config.instance_profile_policies, [
            "Ec2PDReportingPolicy",
          ])
        })
        instance = merge(local.ec2_instances.bods.instance, {
          instance_type = "m6i.2xlarge",
        })
        tags = merge(local.ec2_instances.bods.tags, {
          description                          = "Prod SAP BI Platform ETL installation and configurations"
          instance-scheduling                  = "skip-scheduling"
          nomis-combined-reporting-environment = "pd"
        })
      })

      # Comment out till needed for deployment
      # pd-ncr-etl-2-b = merge(local.ec2_instances.bods, {
      #   # cloudwatch_metric_alarms = local.cloudwatch_metric_alarms.bods # comment in when commissioned
      #   config = merge(local.ec2_instances.bods.config, {
      #     ami_name          = "hmpps_windows_server_2019_release_2024-05-02T00-00-37.552Z"
      #     availability_zone = "eu-west-2b"
      #     instance_profile_policies = concat(local.ec2_instances.bods.config.instance_profile_policies, [
      #       "Ec2PDReportingPolicy",
      #     ])
      #   })
      #   instance = merge(local.ec2_instances.bods.instance, {
      #     instance_type = "m6i.2xlarge",
      #   })
      #   tags = merge(local.ec2_instances.bods.tags, {
      #     description                          = "Prod SAP BI Platform ETL installation and configurations"
      #     instance-scheduling                  = "skip-scheduling"
      #     nomis-combined-reporting-environment = "pd"
      #   })
      # })

      # Comment out till needed for deployment
      pd-ncr-processing-1-a = merge(local.ec2_instances.bip_app, {
        # cloudwatch_metric_alarms = local.cloudwatch_metric_alarms.bip_app # comment in when commissioned
        config = merge(local.ec2_instances.bip_app.config, {
          ami_name          = "base_rhel_8_5_2024-05-01T00-00-19.643Z"
          availability_zone = "eu-west-2a"
          instance_profile_policies = concat(local.ec2_instances.bip_app.config.instance_profile_policies, [
            "Ec2PDReportingPolicy",
          ])
        })
        instance = merge(local.ec2_instances.bip_app.instance, {
          instance_type = "m6i.4xlarge",
        })
        tags = merge(local.ec2_instances.bip_app.tags, {
          description                          = "Prod SAP BI Platform installation and configurations"
          instance-scheduling                  = "skip-scheduling"
          node                                 = "3"
          nomis-combined-reporting-environment = "pd"
          type                                 = "processing"
        })
      })

      # Comment out till needed for deployment
      # pd-ncr-processing-2-b = merge(local.ec2_instances.bip_app, {
      #   # cloudwatch_metric_alarms = local.cloudwatch_metric_alarms.bip_app # comment in when commissioned
      #   config = merge(local.ec2_instances.bip_app.config, {
      #     ami_name          = "base_rhel_8_5_2024-05-01T00-00-19.643Z"
      #     availability_zone = "eu-west-2b"
      #     instance_profile_policies = concat(local.ec2_instances.bip_app.config.instance_profile_policies, [
      #       "Ec2PDReportingPolicy",
      #     ])
      #   })
      #   instance = merge(local.ec2_instances.bip_app.instance, {
      #     instance_type = "m6i.4xlarge",
      #   })
      #   tags = merge(local.ec2_instances.bip_app.tags, {
      #     description                          = "Prod SAP BI Platform installation and configurations"
      #     instance-scheduling                  = "skip-scheduling"
      #     node                                 = "4"
      #     nomis-combined-reporting-environment = "pd"
      #     type                                 = "processing"
      #   })
      # })

      # # Comment out till needed for deployment
      # pd-ncr-processing-3-c = merge(local.ec2_instances.bip_app, {
      #   # cloudwatch_metric_alarms = local.cloudwatch_metric_alarms.bip_app # comment in when commissioned
      #   config = merge(local.ec2_instances.bip_app.config, {
      #     ami_name          = "base_rhel_8_5_2024-05-01T00-00-19.643Z"
      #     availability_zone = "eu-west-2c"
      #     instance_profile_policies = concat(local.ec2_instances.bip_app.config.instance_profile_policies, [
      #       "Ec2PDReportingPolicy",
      #     ])
      #   })
      #   instance = merge(local.ec2_instances.bip_app.instance, {
      #     instance_type = "m6i.4xlarge",
      #   })
      #   tags = merge(local.ec2_instances.bip_app.tags, {
      #     description                          = "Prod SAP BI Platform installation and configurations"
      #     instance-scheduling                  = "skip-scheduling"
      #     node                                 = "5"
      #     nomis-combined-reporting-environment = "pd"
      #     type                                 = "processing"
      #   })
      # })

      # # Comment out till needed for deployment
      # pd-ncr-processing-4-a = merge(local.ec2_instances.bip_app, {
      #   # cloudwatch_metric_alarms = local.cloudwatch_metric_alarms.bip_app # comment in when commissioned
      #   config = merge(local.ec2_instances.bip_app.config, {
      #     ami_name          = "base_rhel_8_5_2024-05-01T00-00-19.643Z"
      #     availability_zone = "eu-west-2a"
      #     instance_profile_policies = concat(local.ec2_instances.bip_app.config.instance_profile_policies, [
      #       "Ec2PDReportingPolicy",
      #     ])
      #   })
      #   instance = merge(local.ec2_instances.bip_app.instance, {
      #     instance_type = "m6i.4xlarge",
      #   })
      #   tags = merge(local.ec2_instances.bip_app.tags, {
      #     description                          = "Prod SAP BI Platform installation and configurations"
      #     instance-scheduling                  = "skip-scheduling"
      #     node                                 = "6"
      #     nomis-combined-reporting-environment = "pd"
      #     type                                 = "processing"
      #   })
      # })

      # Comment out till needed for deployment
      pd-ncr-web-1-a = merge(local.ec2_instances.bip_web, {
        # cloudwatch_metric_alarms = local.cloudwatch_metric_alarms.bip_web # comment in when commissioned
        config = merge(local.ec2_instances.bip_web.config, {
          ami_name          = "base_rhel_8_5_2024-05-01T00-00-19.643Z"
          availability_zone = "eu-west-2a"
          instance_profile_policies = concat(local.ec2_instances.bip_web.config.instance_profile_policies, [
            "Ec2PDReportingPolicy",
          ])
        })
        instance = merge(local.ec2_instances.bip_web.instance, {
          instance_type = "r6i.xlarge",
        })
        tags = merge(local.ec2_instances.bip_web.tags, {
          description                          = "Prod SAP BI Platform web-tier installation and configurations"
          instance-scheduling                  = "skip-scheduling"
          nomis-combined-reporting-environment = "pd"
        })
      })

      # Comment out till needed for deployment
      # pd-ncr-web-2-b = merge(local.ec2_instances.bip_web, {
      #   # cloudwatch_metric_alarms = local.cloudwatch_metric_alarms.bip_web # comment in when commissioned
      #   config = merge(local.ec2_instances.bip_web.config, {
      #     ami_name          = "base_rhel_8_5_2024-05-01T00-00-19.643Z"
      #     availability_zone = "eu-west-2b"
      #     instance_profile_policies = concat(local.ec2_instances.bip_web.config.instance_profile_policies, [
      #       "Ec2PDReportingPolicy",
      #     ])
      #   })
      #   instance = merge(local.ec2_instances.bip_web.instance, {
      #     instance_type = "r6i.xlarge",
      #   })
      #   tags = merge(local.ec2_instances.bip_web.tags, {
      #     description                          = "Prod SAP BI Platform web-tier installation and configurations"
      #     instance-scheduling                  = "skip-scheduling"
      #     nomis-combined-reporting-environment = "pd"
      #   })
      # })

      # # Comment out till needed for deployment
      # pd-ncr-web-3-c = merge(local.ec2_instances.bip_web, {
      #   # cloudwatch_metric_alarms = local.cloudwatch_metric_alarms.bip_web # comment in when commissioned
      #   config = merge(local.ec2_instances.bip_web.config, {
      #     ami_name          = "base_rhel_8_5_2024-05-01T00-00-19.643Z"
      #     availability_zone = "eu-west-2c"
      #     instance_profile_policies = concat(local.ec2_instances.bip_web.config.instance_profile_policies, [
      #       "Ec2PDReportingPolicy",
      #     ])
      #   })
      #   instance = merge(local.ec2_instances.bip_web.instance, {
      #     instance_type = "r6i.xlarge",
      #   })
      #   tags = merge(local.ec2_instances.bip_web.tags, {
      #     description                          = "Prod SAP BI Platform web-tier installation and configurations"
      #     instance-scheduling                  = "skip-scheduling"
      #     nomis-combined-reporting-environment = "pd"
      #   })
      # })

      # # Comment out till needed for deployment
      # pd-ncr-web-4-a = merge(local.ec2_instances.bip_web, {
      #   # cloudwatch_metric_alarms = local.cloudwatch_metric_alarms.bip_web # comment in when commissioned
      #   config = merge(local.ec2_instances.bip_web.config, {
      #     ami_name          = "base_rhel_8_5_2024-05-01T00-00-19.643Z"
      #     availability_zone = "eu-west-2a"
      #     instance_profile_policies = concat(local.ec2_instances.bip_web.config.instance_profile_policies, [
      #       "Ec2PDReportingPolicy",
      #     ])
      #   })
      #   instance = merge(local.ec2_instances.bip_web.instance, {
      #     instance_type = "r6i.xlarge",
      #   })
      #   tags = merge(local.ec2_instances.bip_web.tags, {
      #     description                          = "Prod SAP BI Platform web-tier installation and configurations"
      #     instance-scheduling                  = "skip-scheduling"
      #     nomis-combined-reporting-environment = "pd"
      #   })
      # })

      pd-ncr-web-admin-a = merge(local.ec2_instances.bip_web, {
        # cloudwatch_metric_alarms = local.cloudwatch_metric_alarms.bip_web # comment in when commissioned
        config = merge(local.ec2_instances.bip_web.config, {
          ami_name          = "base_rhel_8_5_2024-05-01T00-00-19.643Z"
          availability_zone = "eu-west-2a"
          instance_profile_policies = concat(local.ec2_instances.bip_web.config.instance_profile_policies, [
            "Ec2PDReportingPolicy",
          ])
        })
        instance = merge(local.ec2_instances.bip_web.instance, {
          instance_type = "r6i.large",
        })
        tags = merge(local.ec2_instances.bip_web.tags, {
          description                          = "Prod SAP BI Platform web-tier admin installation and configurations"
          instance-scheduling                  = "skip-scheduling"
          nomis-combined-reporting-environment = "pd"
        })
      })
    }

    # Comment out till needed for deployment
    efs = {
      pd-ncr-sap-share = local.efs.sap_share
    }

    iam_policies = {
      Ec2PDDatabasePolicy = {
        description = "Permissions required for PROD Database EC2s"
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
              "arn:aws:secretsmanager:*:*:secret:/oracle/database/*PD/*",
              "arn:aws:secretsmanager:*:*:secret:/oracle/database/PD*/*",
            ]
          }
        ]
      }
      Ec2PDReportingPolicy = {
        description = "Permissions required for PD reporting EC2s"
        statements = [
          {
            effect = "Allow"
            actions = [
              "secretsmanager:GetSecretValue",
              "secretsmanager:PutSecretValue",
            ]
            resources = [
              "arn:aws:secretsmanager:*:*:secret:/ec2/ncr-bip/pd/*",
              "arn:aws:secretsmanager:*:*:secret:/ec2/ncr-web/pd/*",
            ]
          }
        ]
      }
    }

    lbs = {
      private = merge(local.lbs.private, {

        instance_target_groups = {
          pd-ncr-web = merge(local.lbs.private.instance_target_groups.web, {
            attachments = [
              { ec2_instance_name = "pd-ncr-web-1-a" },
              # add more instances here when deployed
            ]
          })
        }
        listeners = merge(local.lbs.private.listeners, {
          https = merge(local.lbs.private.listeners.https, {
            certificate_names_or_arns = ["nomis_combined_reporting_wildcard_cert"]

            rules = {
              pd-ncr-web = {
                priority = 4580
                actions = [{
                  type              = "forward"
                  target_group_name = "pd-ncr-web"
                }]
                conditions = [{
                  host_header = {
                    values = [
                      "production.reporting.nomis.service.justice.gov.uk",
                      "reporting.nomis.service.justice.gov.uk",
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
      "reporting.nomis.service.justice.gov.uk" = {
        ns_records = [
          # use this if NS records can be pulled from terrafrom, otherwise use records variable
          { name = "production", ttl = "86400", zone_name = "production.reporting.nomis.service.justice.gov.uk" }
        ]
        records = [
          { name = "development", type = "NS", ttl = "86400", records = ["ns-104.awsdns-13.com", "ns-1357.awsdns-41.org", "ns-1718.awsdns-22.co.uk", "ns-812.awsdns-37.net"] },
          { name = "test", type = "NS", ttl = "86400", records = ["ns-1011.awsdns-62.net", "ns-1090.awsdns-08.org", "ns-1938.awsdns-50.co.uk", "ns-390.awsdns-48.com"] },
          { name = "preproduction", type = "NS", ttl = "86400", records = ["ns-1525.awsdns-62.org", "ns-1563.awsdns-03.co.uk", "ns-38.awsdns-04.com", "ns-555.awsdns-05.net"] },
          { name = "lsast", type = "NS", ttl = "86400", records = ["ns-1285.awsdns-32.org", "ns-1780.awsdns-30.co.uk", "ns-198.awsdns-24.com", "ns-852.awsdns-42.net"] },
          { name = "db-a", type = "CNAME", ttl = "300", records = ["pd-ncr-db-1-a.nomis-combined-reporting.hmpps-production.modernisation-platform.service.justice.gov.uk"] },
          { name = "db-b", type = "CNAME", ttl = "300", records = ["pd-ncr-db-1-b.nomis-combined-reporting.hmpps-production.modernisation-platform.service.justice.gov.uk"] },
        ]
      }

      "production.reporting.nomis.service.justice.gov.uk" = {
      }
    }

    secretsmanager_secrets = {
      "/ec2/ncr-bip/pd"           = local.secretsmanager_secrets.bip_app
      "/ec2/ncr-web/pd"           = local.secretsmanager_secrets.bip_web
      "/oracle/database/PDBIPSYS" = local.secretsmanager_secrets.db # Azure Live System DB
      "/oracle/database/PDBIPAUD" = local.secretsmanager_secrets.db # Azure Live Audit DB
      "/oracle/database/PDBISYS"  = local.secretsmanager_secrets.db
      "/oracle/database/PDBIAUD"  = local.secretsmanager_secrets.db
    }
  }
}
