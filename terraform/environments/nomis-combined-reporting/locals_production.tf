locals {

  baseline_presets_production = {
    options = {
      sns_topics = {
        pagerduty_integrations = {
          pagerduty = "nomis-combined-reporting-production"
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

      pd-ncr-app-1 = merge(local.ec2_instances.bip_app, {
        config = merge(local.ec2_instances.bip_app.config, {
          availability_zone = "eu-west-2a"
          instance_profile_policies = concat(local.ec2_instances.bip_app.config.instance_profile_policies, [
            "Ec2PDReportingPolicy",
          ])
        })
        tags = merge(local.ec2_instances.bip_app.tags, {
          instance-scheduling                  = "skip-scheduling"
          nomis-combined-reporting-environment = "pd"
        })
      })
      pd-ncr-app-2 = merge(local.ec2_instances.bip_app, {
        config = merge(local.ec2_instances.bip_app.config, {
          availability_zone = "eu-west-2b"
          instance_profile_policies = concat(local.ec2_instances.bip_app.config.instance_profile_policies, [
            "Ec2PDReportingPolicy",
          ])
        })
        tags = merge(local.ec2_instances.bip_app.tags, {
          instance-scheduling                  = "skip-scheduling"
          nomis-combined-reporting-environment = "pd"
        })
      })
      pd-ncr-app-3 = merge(local.ec2_instances.bip_app, {
        config = merge(local.ec2_instances.bip_app.config, {
          availability_zone = "eu-west-2a"
          instance_profile_policies = concat(local.ec2_instances.bip_app.config.instance_profile_policies, [
            "Ec2PDReportingPolicy",
          ])
        })
        tags = merge(local.ec2_instances.bip_app.tags, {
          instance-scheduling                  = "skip-scheduling"
          nomis-combined-reporting-environment = "pd"
        })
      })
      pd-ncr-app-4 = merge(local.ec2_instances.bip_app, {
        config = merge(local.ec2_instances.bip_app.config, {
          availability_zone = "eu-west-2b"
          instance_profile_policies = concat(local.ec2_instances.bip_app.config.instance_profile_policies, [
            "Ec2PDReportingPolicy",
          ])
        })
        tags = merge(local.ec2_instances.bip_app.tags, {
          instance-scheduling                  = "skip-scheduling"
          nomis-combined-reporting-environment = "pd"
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
        ebs_volumes = {
          "/dev/sdb" = { type = "gp3", label = "app", size = 100 }   # /u01
          "/dev/sdc" = { type = "gp3", label = "app", size = 500 }   # /u02
          "/dev/sde" = { type = "gp3", label = "data", size = 500 }  # DATA01
          "/dev/sdj" = { type = "gp3", label = "flash", size = 250 } # FLASH01
          "/dev/sds" = { type = "gp3", label = "swap", size = 4 }
        }
        tags = merge(local.ec2_instances.db.tags, {
          description                          = "PROD NCR DATABASE"
          nomis-combined-reporting-environment = "pd"
          oracle-sids                          = "PDBIPSYS PDBIPAUD PDBISYS PDBIAUD"
        })
      })

      pd-ncr-db-1-b = merge(local.ec2_instances.db, {
        cloudwatch_metric_alarms = merge(
          local.cloudwatch_metric_alarms.db,
          local.cloudwatch_metric_alarms.db_connected,
        )
        config = merge(local.ec2_instances.db.config, {
          availability_zone = "eu-west-2b"
          instance_profile_policies = concat(local.ec2_instances.db.config.instance_profile_policies, [
            "Ec2PDDatabasePolicy",
          ])
        })
        tags = merge(local.ec2_instances.db.tags, {
          description                          = "PROD NCR DATABASE"
          nomis-combined-reporting-environment = "pd"
          oracle-sids                          = "DRBIPSYS DRBIPAUD DRBISYS DRBIAUD"
        })
      })

      pd-ncr-cms-1 = merge(local.ec2_instances.bip_cms, {
        config = merge(local.ec2_instances.bip_cms.config, {
          availability_zone = "eu-west-2a"
          instance_profile_policies = concat(local.ec2_instances.bip_cms.config.instance_profile_policies, [
            "Ec2PDReportingPolicy",
          ])
        })
        tags = merge(local.ec2_instances.bip_cms.tags, {
          nomis-combined-reporting-environment = "pd"
        })
      })

      pd-ncr-cms-2 = merge(local.ec2_instances.bip_cms, {
        config = merge(local.ec2_instances.bip_cms.config, {
          availability_zone = "eu-west-2b"
          instance_profile_policies = concat(local.ec2_instances.bip_cms.config.instance_profile_policies, [
            "Ec2PDReportingPolicy",
          ])
        })
        tags = merge(local.ec2_instances.bip_cms.tags, {
          nomis-combined-reporting-environment = "pd"
        })
      })

      pd-ncr-webadmin-1 = merge(local.ec2_instances.bip_webadmin, {
        config = merge(local.ec2_instances.bip_webadmin.config, {
          availability_zone = "eu-west-2a"
          instance_profile_policies = concat(local.ec2_instances.bip_webadmin.config.instance_profile_policies, [
            "Ec2PDReportingPolicy",
          ])
        })
        tags = merge(local.ec2_instances.bip_webadmin.tags, {
          nomis-combined-reporting-environment = "pd"
        })
      })

      pd-ncr-web-1 = merge(local.ec2_instances.bip_web, {
        config = merge(local.ec2_instances.bip_web.config, {
          availability_zone = "eu-west-2a"
          instance_profile_policies = concat(local.ec2_instances.bip_web.config.instance_profile_policies, [
            "Ec2PDReportingPolicy",
          ])
        })
        tags = merge(local.ec2_instances.bip_web.tags, {
          nomis-combined-reporting-environment = "pd"
        })
      })
    }

    efs = {
      pd-ncr-sap-share = {
        access_points = {
          root = {
            posix_user = {
              gid = 1201 # binstall
              uid = 1201 # bobj
            }
            root_directory = {
              path = "/"
              creation_info = {
                owner_gid   = 1201 # binstall
                owner_uid   = 1201 # bobj
                permissions = "0777"
              }
            }
          }
        }
        file_system = {
          availability_zone_name = "eu-west-2a"
          lifecycle_policy = {
            transition_to_ia = "AFTER_30_DAYS"
          }
        }
        mount_targets = [{
          subnet_name        = "private"
          availability_zones = ["eu-west-2a"]
          security_groups    = ["bip"]
        }]
        tags = {
          backup      = "false"
          backup-plan = "daily-and-weekly"
        }
      }
      pd-ncr-sap-share-multiaz = {
        access_points = {
          root = {
            posix_user = {
              gid = 1201 # binstall
              uid = 1201 # bobj
            }
            root_directory = {
              path = "/"
              creation_info = {
                owner_gid   = 1201 # binstall
                owner_uid   = 1201 # bobj
                permissions = "0777"
              }
            }
          }
        }
        file_system = {
          lifecycle_policy = {
            transition_to_ia = "AFTER_30_DAYS"
          }
        }
        mount_targets = [{
          subnet_name        = "private"
          availability_zones = ["eu-west-2a", "eu-west-2b", "eu-west-2c"]
          security_groups    = ["bip"]
        }]
        tags = {
          backup      = "false"
          backup-plan = "daily-and-weekly"
        }
      }
    }

    iam_policies = {
      Ec2PDDatabasePolicy = {
        description = "Permissions required for PROD Database EC2s"
        statements = [
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
              "arn:aws:secretsmanager:*:*:secret:/sap/bip/pd/*",
              "arn:aws:secretsmanager:*:*:secret:/sap/bods/pd/*",
              "arn:aws:secretsmanager:*:*:secret:/oracle/database/*PD/*",
              "arn:aws:secretsmanager:*:*:secret:/oracle/database/PD*/*",
            ]
          },
          {
            effect = "Allow"
            actions = [
              "elasticloadbalancing:Describe*",
            ]
            resources = ["*"]
          },
          {
            effect = "Allow"
            actions = [
              "elasticloadbalancing:SetRulePriorities",
            ]
            resources = [
              "arn:aws:elasticloadbalancing:*:*:listener-rule/app/private-lb/*",
              "arn:aws:elasticloadbalancing:*:*:listener-rule/app/public-lb/*",
            ]
          }
        ]
      }
    }

    lbs = {
      private = merge(local.lbs.private, {
        instance_target_groups = {
          private-pd-http-7777 = merge(local.lbs.private.instance_target_groups.http-7777, {
            attachments = [
              { ec2_instance_name = "pd-ncr-web-1" },
            ]
          })
        }
        listeners = merge(local.lbs.private.listeners, {
          http-7777 = merge(local.lbs.private.listeners.http-7777, {
            alarm_target_group_names = []
            rules = {
              web = {
                priority = 200
                actions = [{
                  type              = "forward"
                  target_group_name = "private-pd-http-7777"
                }]
                conditions = [{
                  host_header = {
                    values = [
                      "int.reporting.nomis.service.justice.gov.uk",
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
                      "int.reporting.nomis.service.justice.gov.uk",
                      "maintenance-int.reporting.nomis.service.justice.gov.uk",
                    ]
                  }
                }]
              }
            }
          })
        })
      })

      public = merge(local.lbs.public, {
        instance_target_groups = {
          pd-http-7010 = merge(local.lbs.public.instance_target_groups.http-7010, {
            attachments = [
              { ec2_instance_name = "pd-ncr-webadmin-1" },
            ]
          })
          pd-http-7777 = merge(local.lbs.public.instance_target_groups.http-7777, {
            attachments = [
              { ec2_instance_name = "pd-ncr-web-1" },
            ]
          })
        }
        listeners = merge(local.lbs.public.listeners, {
          https = merge(local.lbs.public.listeners.https, {
            alarm_target_group_names = []
            rules = {
              webadmin = {
                priority = 100
                actions = [{
                  type              = "forward"
                  target_group_name = "pd-http-7010"
                }]
                conditions = [{
                  host_header = {
                    values = [
                      "admin.reporting.nomis.service.justice.gov.uk",
                    ]
                  }
                }]
              }
              web = {
                priority = 200
                actions = [{
                  type              = "forward"
                  target_group_name = "pd-http-7777"
                }]
                conditions = [{
                  host_header = {
                    values = [
                      "reporting.nomis.service.justice.gov.uk",
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
                      "admin.reporting.nomis.service.justice.gov.uk",
                      "maintenance.reporting.nomis.service.justice.gov.uk",
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
        lb_alias_records = [
          { name = "", type = "A", lbs_map_key = "public" },
          { name = "admin", type = "A", lbs_map_key = "public" },
          { name = "int", type = "A", lbs_map_key = "private" },
          { name = "maintenance", type = "A", lbs_map_key = "public" },
          { name = "maintenance-int", type = "A", lbs_map_key = "private" },
        ]
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
      "/oracle/database/PDBIPSYS" = local.secretsmanager_secrets.db # Azure Live System DB
      "/oracle/database/PDBIPAUD" = local.secretsmanager_secrets.db # Azure Live Audit DB
      "/oracle/database/PDBISYS"  = local.secretsmanager_secrets.db # AWS System DB
      "/oracle/database/PDBIAUD"  = local.secretsmanager_secrets.db # AWS Audit DB
      "/oracle/database/DRBIPSYS" = local.secretsmanager_secrets.db
      "/oracle/database/DRBIPAUD" = local.secretsmanager_secrets.db
      "/oracle/database/DRBISYS"  = local.secretsmanager_secrets.db
      "/oracle/database/DRBIAUD"  = local.secretsmanager_secrets.db
      "/sap/bip/pd"               = local.secretsmanager_secrets.bip
      "/sap/bods/pd"              = local.secretsmanager_secrets.bods
    }
  }
}
