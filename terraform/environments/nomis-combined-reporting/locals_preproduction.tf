locals {

  lb_maintenance_message_preproduction = {
    maintenance_title   = "Prison-NOMIS Reporting LSAST and/or Pre-Production Maintenance Window"
    maintenance_message = "Prison-NOMIS Reporting LSAST and/or Pre-Production is currently unavailable due to planned maintenance or out-of-hours shutdown (7pm-7am). Please contact <a href=\"https://moj.enterprise.slack.com/archives/C6D94J81E\">#ask-digital-studio-ops</a> slack channel if environment is unexpectedly down."
  }

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

    cloudwatch_dashboards = {
      "CloudWatch-Default" = {
        periodOverride = "auto"
        start          = "-PT6H"
        widget_groups = [
          module.baseline_presets.cloudwatch_dashboard_widget_groups.lb,
          local.cloudwatch_dashboard_widget_groups.all_ec2,
          local.cloudwatch_dashboard_widget_groups.db,
          local.cloudwatch_dashboard_widget_groups.cms,
          local.cloudwatch_dashboard_widget_groups.app,
          local.cloudwatch_dashboard_widget_groups.web,
          local.cloudwatch_dashboard_widget_groups.webadmin,
          module.baseline_presets.cloudwatch_dashboard_widget_groups.ssm_command,
        ]
      }
    }

    ec2_instances = {

      ls-ncr-db-1-a = merge(local.ec2_instances.db, {
        cloudwatch_metric_alarms = {}
        #cloudwatch_metric_alarms = merge(
        #  local.cloudwatch_metric_alarms.db,
        #  local.cloudwatch_metric_alarms.db_connected,
        #  local.cloudwatch_metric_alarms.db_backup,
        #)
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

      pp-ncr-app-1 = merge(local.ec2_instances.bip_app, {
        config = merge(local.ec2_instances.bip_app.config, {
          availability_zone = "eu-west-2a"
          instance_profile_policies = concat(local.ec2_instances.bip_app.config.instance_profile_policies, [
            "Ec2PPReportingPolicy",
          ])
        })
        tags = merge(local.ec2_instances.bip_app.tags, {
          instance-scheduling                  = "skip-scheduling"
          nomis-combined-reporting-environment = "pp"
        })
      })

      pp-ncr-cms-1 = merge(local.ec2_instances.bip_cms, {
        config = merge(local.ec2_instances.bip_cms.config, {
          availability_zone = "eu-west-2a"
          instance_profile_policies = concat(local.ec2_instances.bip_cms.config.instance_profile_policies, [
            "Ec2PPReportingPolicy",
          ])
        })
        tags = merge(local.ec2_instances.bip_cms.tags, {
          instance-scheduling                  = "skip-scheduling"
          nomis-combined-reporting-environment = "pp"
        })
      })

      pp-ncr-cms-2 = merge(local.ec2_instances.bip_cms, {
        config = merge(local.ec2_instances.bip_cms.config, {
          availability_zone = "eu-west-2b"
          instance_profile_policies = concat(local.ec2_instances.bip_cms.config.instance_profile_policies, [
            "Ec2PPReportingPolicy",
          ])
        })
        tags = merge(local.ec2_instances.bip_cms.tags, {
          instance-scheduling                  = "skip-scheduling"
          nomis-combined-reporting-environment = "pp"
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
          oracle-sids                          = "PPBISYS PPBIAUD"
          instance-scheduling                  = "skip-scheduling"
        })
      })

      pp-ncr-webadmin-1 = merge(local.ec2_instances.bip_webadmin, {
        config = merge(local.ec2_instances.bip_webadmin.config, {
          availability_zone = "eu-west-2a"
          instance_profile_policies = concat(local.ec2_instances.bip_webadmin.config.instance_profile_policies, [
            "Ec2PPReportingPolicy",
          ])
        })
        tags = merge(local.ec2_instances.bip_webadmin.tags, {
          instance-scheduling                  = "skip-scheduling"
          nomis-combined-reporting-environment = "pp"
        })
      })

      pp-ncr-web-1 = merge(local.ec2_instances.bip_web, {
        config = merge(local.ec2_instances.bip_web.config, {
          availability_zone = "eu-west-2a"
          instance_profile_policies = concat(local.ec2_instances.bip_web.config.instance_profile_policies, [
            "Ec2PPReportingPolicy",
          ])
        })
        tags = merge(local.ec2_instances.bip_web.tags, {
          instance-scheduling                  = "skip-scheduling"
          nomis-combined-reporting-environment = "pp"
        })
      })
    }

    efs = {
      pp-ncr-sap-share = {
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
          security_groups    = ["efs"]
        }]
        tags = {
          backup      = "false"
          backup-plan = "daily-and-weekly"
        }
      }
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
              "arn:aws:secretsmanager:*:*:secret:/sap/bip/lsast/*",
              "arn:aws:secretsmanager:*:*:secret:/oracle/database/*LS/*",
              "arn:aws:secretsmanager:*:*:secret:/oracle/database/LS*/*",
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
              "arn:aws:secretsmanager:*:*:secret:/sap/bip/pp/*",
              "arn:aws:secretsmanager:*:*:secret:/oracle/database/*PP/*",
              "arn:aws:secretsmanager:*:*:secret:/oracle/database/PP*/*",
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
          private-pp-http-7777 = merge(local.lbs.private.instance_target_groups.http-7777, {
            attachments = [
              { ec2_instance_name = "pp-ncr-web-1" },
            ]
          })
        }
        listeners = merge(local.lbs.private.listeners, {
          http-7777 = merge(local.lbs.private.listeners.http-7777, {
            alarm_target_group_names = [] # don't enable as environments are powered up/down frequently
            rules = {
              web = {
                priority = 200
                actions = [{
                  type              = "forward"
                  target_group_name = "private-pp-http-7777"
                }]
                conditions = [{
                  host_header = {
                    values = [
                      "int.preproduction.reporting.nomis.service.justice.gov.uk",
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
                      "int.preproduction.reporting.nomis.service.justice.gov.uk",
                      "maintenance-int.preproduction.reporting.nomis.service.justice.gov.uk",
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
          pp-http-7010 = merge(local.lbs.public.instance_target_groups.http-7010, {
            attachments = [
              { ec2_instance_name = "pp-ncr-webadmin-1" },
            ]
          })
          pp-http-7777 = merge(local.lbs.public.instance_target_groups.http-7777, {
            attachments = [
              { ec2_instance_name = "pp-ncr-web-1" },
            ]
          })
        }
        listeners = merge(local.lbs.public.listeners, {
          https = merge(local.lbs.public.listeners.https, {
            alarm_target_group_names = [] # don't enable as environments are powered up/down frequently
            rules = {
              webadmin = {
                priority = 100
                actions = [{
                  type              = "forward"
                  target_group_name = "pp-http-7010"
                }]
                conditions = [{
                  host_header = {
                    values = [
                      "admin.preproduction.reporting.nomis.service.justice.gov.uk",
                    ]
                  }
                }]
              }
              web = {
                priority = 200
                actions = [{
                  type              = "forward"
                  target_group_name = "pp-http-7777"
                }]
                conditions = [{
                  host_header = {
                    values = [
                      "preproduction.reporting.nomis.service.justice.gov.uk",
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
                      "admin.preproduction.reporting.nomis.service.justice.gov.uk",
                      "maintenance.preproducion.reporting.nomis.service.justice.gov.uk",
                      "preproduction.reporting.nomis.service.justice.gov.uk",
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
        ]
        lb_alias_records = [
          { name = "", type = "A", lbs_map_key = "public" },
          { name = "admin", type = "A", lbs_map_key = "public" },
          { name = "int", type = "A", lbs_map_key = "private" },
          { name = "maintenance", type = "A", lbs_map_key = "public" },
          { name = "maintenance-int", type = "A", lbs_map_key = "private" },
        ]
      }
    }

    secretsmanager_secrets = {
      "/oracle/database/PPBIPSYS" = local.secretsmanager_secrets.db
      "/oracle/database/PPBIPAUD" = local.secretsmanager_secrets.db
      "/oracle/database/PPBISYS"  = local.secretsmanager_secrets.db
      "/oracle/database/PPBIAUD"  = local.secretsmanager_secrets.db
      "/oracle/database/LSBIPSYS" = local.secretsmanager_secrets.db
      "/oracle/database/LSBIPAUD" = local.secretsmanager_secrets.db
      "/oracle/database/LSBISYS"  = local.secretsmanager_secrets.db
      "/oracle/database/LSBIAUD"  = local.secretsmanager_secrets.db
      "/sap/bip/lsast"            = local.secretsmanager_secrets.bip
      "/sap/bip/pp"               = local.secretsmanager_secrets.bip
    }
  }
}
