locals {

  lb_maintenance_message_development = {
    maintenance_title   = "Prison-NOMIS Maintenance Window"
    maintenance_message = "Prison-NOMIS is currently unavailable due to planned maintenance. Please try again later"
  }

  baseline_presets_development = {
    options = {
      sns_topics = {
        pagerduty_integrations = {
          pagerduty = "nomis-development"
        }
      }
    }
  }

  # please keep resources in alphabetical order
  baseline_development = {

    acm_certificates = {
      nomis_wildcard_cert_v2 = {
        cloudwatch_metric_alarms = module.baseline_presets.cloudwatch_metric_alarms.acm
        domain_name              = "*.development.nomis.service.justice.gov.uk"
        subject_alternate_names = [
          "*.nomis.hmpps-development.modernisation-platform.service.justice.gov.uk",
        ]
        tags = {
          description = "wildcard cert for nomis development domains"
        }
      }
    }

    backup_plans = {
      # delete once qa11g-nomis-web12-a removed
      qa11g-nomis-web12-a-workaround = {
        rule = {
          schedule          = "cron(30 23 ? * MON-FRI *)"
          start_window      = 60
          completion_window = 3600
          delete_after      = 10
        }
        selection = {
          selection_tags = [{
            type  = "STRINGEQUALS"
            key   = "server-name"
            value = "qa11g-nomis-web12-a"
          }]
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
          local.cloudwatch_dashboard_widget_groups.syscon,
          local.cloudwatch_dashboard_widget_groups.asg,
          module.baseline_presets.cloudwatch_dashboard_widget_groups.ssm_command,
        ]
      }
    }

    ec2_autoscaling_groups = {
      dev-base-ol85 = merge(local.ec2_autoscaling_groups.base, {
        config = merge(local.ec2_autoscaling_groups.base.config, {
          ami_name = "base_ol_8_5*"
        })
        user_data_cloud_init = merge(local.ec2_autoscaling_groups.base.user_data_cloud_init, {
          args = merge(local.ec2_autoscaling_groups.base.user_data_cloud_init.args, {
            branch = "main"
          })
        })
        tags = merge(local.ec2_autoscaling_groups.base.tags, {
          ami         = "base_ol_8_5"
          description = "For testing our base OL 8.5 base image"
          server-type = "base-ol85"
        })
      })

      dev-base-rhel610 = merge(local.ec2_autoscaling_groups.base, {
        config = merge(local.ec2_autoscaling_groups.base.config, {
          ami_name = "base_rhel_6_10*"
        })
        instance = merge(local.ec2_autoscaling_groups.base.instance, {
          instance_type                = "t2.medium"
          metadata_options_http_tokens = "optional"
        })
        user_data_cloud_init = merge(local.ec2_autoscaling_groups.base.user_data_cloud_init, {
          args = merge(local.ec2_autoscaling_groups.base.user_data_cloud_init.args, {
            branch = "main"
          })
        })
        tags = merge(local.ec2_autoscaling_groups.base.tags, {
          ami         = "base_rhel_6_10"
          description = "For testing our base RHEL6.10 base image"
          server-type = "base-rhel610"
        })
      })

      dev-base-rhel79 = merge(local.ec2_autoscaling_groups.base, {
        config = merge(local.ec2_autoscaling_groups.base.config, {
          ami_name = "base_rhel_7_9_*"
        })
        user_data_cloud_init = merge(local.ec2_autoscaling_groups.base.user_data_cloud_init, {
          args = merge(local.ec2_autoscaling_groups.base.user_data_cloud_init.args, {
            branch = "main"
          })
        })
        tags = merge(local.ec2_autoscaling_groups.base.tags, {
          ami         = "base_rhel_7_9"
          description = "For testing our base RHEL7.9 base image"
          server-type = "base-rhel79"
        })
      })

      dev-base-rhel85 = merge(local.ec2_autoscaling_groups.base, {
        config = merge(local.ec2_autoscaling_groups.base.config, {
          ami_name = "base_rhel_8_5_*"
        })
        user_data_cloud_init = merge(local.ec2_autoscaling_groups.base.user_data_cloud_init, {
          args = merge(local.ec2_autoscaling_groups.base.user_data_cloud_init.args, {
            branch = "main"
          })
        })
        tags = merge(local.ec2_autoscaling_groups.base.tags, {
          ami         = "base_rhel_8_5"
          description = "For testing our base RHEL8.5 base image"
          server-type = "base-rhel85"
        })
      })

      dev-nomis-client-a = merge(local.ec2_autoscaling_groups.client, {
        tags = merge(local.ec2_autoscaling_groups.client.tags, {
          domain-name = "azure.noms.root"
        })
      })

      # remember to delete associated backup plan
      qa11g-nomis-web12-a = merge(local.ec2_autoscaling_groups.web12, {
        autoscaling_schedules = {}
        config = merge(local.ec2_autoscaling_groups.web12.config, {
          instance_profile_policies = concat(local.ec2_instances.db.config.instance_profile_policies, [
            "Ec2Qa11GWeblogicPolicy",
          ])
        })
        user_data_cloud_init = merge(local.ec2_autoscaling_groups.web12.user_data_cloud_init, {
          args = merge(local.ec2_autoscaling_groups.web12.user_data_cloud_init.args, {
            branch = "main"
          })
        })
        tags = merge(local.ec2_autoscaling_groups.web12.tags, {
          nomis-environment = "qa11g"
        })
      })
    }

    ec2_instances = {
      dev-nomis-build-a = merge(local.ec2_instances.build, {
        config = merge(local.ec2_instances.build.config, {
          availability_zone = "eu-west-2a"
          instance_profile_policies = concat(local.ec2_instances.build.config.instance_profile_policies, [
            "Ec2DevWeblogicPolicy",
            "Ec2Qa11GWeblogicPolicy",
            "Ec2Qa11RWeblogicPolicy",
          ])
        })
        user_data_cloud_init = merge(local.ec2_instances.build.user_data_cloud_init, {
          args = merge(local.ec2_instances.build.user_data_cloud_init.args, {
            branch = "main"
          })
        })
        tags = merge(local.ec2_instances.build.tags, {
          description         = "Syscon build and release server"
          instance-scheduling = "skip-scheduling"
          update-ssm-agent    = "patchgroup2"
        })
      })

      dev-nomis-db-1-a = merge(local.ec2_instances.db, {
        config = merge(local.ec2_instances.db.config, {
          ami_name          = "nomis_rhel_7_9_oracledb_11_2_release_2023-07-02T00-00-39.521Z"
          availability_zone = "eu-west-2a"
          instance_profile_policies = concat(local.ec2_instances.db.config.instance_profile_policies, [
            "Ec2DevDatabasePolicy",
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
          description         = "syscon nomis dev and qa databases"
          instance-scheduling = "skip-scheduling"
          nomis-environment   = "dev"
          oracle-sids         = ""
          update-ssm-agent    = "patchgroup2"
        })
      })

      dev-nomis-db19c-1-a = merge(local.ec2_instances.db19c, {
        config = merge(local.ec2_instances.db19c.config, {
          availability_zone = "eu-west-2a"
          instance_profile_policies = concat(local.ec2_instances.db19c.config.instance_profile_policies, [
            "Ec2DevDatabasePolicy",
          ])
        })
        ebs_volumes = merge(local.ec2_instances.db19c.ebs_volumes, {
          "/dev/sdb" = { label = "app", size = 100 }
          "/dev/sdc" = { label = "app", size = 100 }
        })
        ebs_volume_config = merge(local.ec2_instances.db19c.ebs_volume_config, {
          data  = { total_size = 500 }
          flash = { total_size = 50 }
        })
        instance = merge(local.ec2_instances.db19c.instance, {
          # disable_api_termination = true
        })
        user_data_cloud_init = merge(local.ec2_instances.db19c.user_data_cloud_init, {
          args = merge(local.ec2_instances.db19c.user_data_cloud_init.args, {
            branch = "main"
          })
        })
        tags = merge(local.ec2_instances.db19c.tags, {
          description         = "syscon nomis dev and qa Oracle 19c databases"
          instance-scheduling = "skip-scheduling"
          nomis-environment   = "dev"
          oracle-sids         = ""
        })
      })

      dev-nomis-web-a = merge(local.ec2_instances.web, {
        config = merge(local.ec2_instances.web.config, {
          availability_zone = "eu-west-2a"
          instance_profile_policies = concat(local.ec2_instances.web.config.instance_profile_policies, [
            "Ec2DevWeblogicPolicy",
          ])
        })
        instance = merge(local.ec2_instances.web.instance, {
          disable_api_termination = true
          instance_type           = "t2.large"
          tags = {
            backup-plan = "daily-and-weekly"
          }
        })
        user_data_cloud_init = merge(local.ec2_instances.web.user_data_cloud_init, {
          args = merge(local.ec2_instances.web.user_data_cloud_init.args, {
            branch = "main"
          })
        })
        tags = merge(local.ec2_instances.web.tags, {
          instance-scheduling  = "skip-scheduling"
          nomis-environment    = "dev"
          oracle-db-hostname-a = "dev-nomis-db-1-a"
          oracle-db-hostname-b = "none"
          oracle-db-name       = "dev"
        })
      })

      qa11g-nomis-web-a = merge(local.ec2_instances.web, {
        config = merge(local.ec2_instances.web.config, {
          availability_zone = "eu-west-2a"
          instance_profile_policies = concat(local.ec2_instances.web.config.instance_profile_policies, [
            "Ec2Qa11GWeblogicPolicy",
          ])
        })
        instance = merge(local.ec2_instances.web.instance, {
          disable_api_termination = true
          instance_type           = "t2.large"
          tags = {
            backup-plan = "daily-and-weekly"
          }
        })
        user_data_cloud_init = merge(local.ec2_instances.web.user_data_cloud_init, {
          args = merge(local.ec2_instances.web.user_data_cloud_init.args, {
            branch = "main"
          })
        })
        tags = merge(local.ec2_instances.web.tags, {
          instance-scheduling  = "skip-scheduling"
          nomis-environment    = "qa11g"
          oracle-db-hostname-a = "dev-nomis-db-1-a"
          oracle-db-hostname-b = "none"
          oracle-db-name       = "qa11g"
        })
      })

      # built by code and then handed over to Syscon for remaining manual configuration
      qa11g-nomis-web12-b = merge(local.ec2_instances.web12, {
        config = merge(local.ec2_instances.web12.config, {
          availability_zone = "eu-west-2b"
          instance_profile_policies = concat(local.ec2_instances.db.config.instance_profile_policies, [
            "Ec2Qa11GWeblogicPolicy",
          ])
        })
        user_data_cloud_init = merge(local.ec2_instances.web12.user_data_cloud_init, {
          args = merge(local.ec2_instances.web12.user_data_cloud_init.args, {
            branch = "main"
          })
        })
        tags = merge(local.ec2_instances.web12.tags, {
          nomis-environment = "qa11g"
        })
      })

      qa11r-nomis-web-a = merge(local.ec2_instances.web, {
        config = merge(local.ec2_instances.web.config, {
          availability_zone = "eu-west-2a"
          instance_profile_policies = concat(local.ec2_instances.web.config.instance_profile_policies, [
            "Ec2Qa11RWeblogicPolicy",
          ])
        })
        instance = merge(local.ec2_instances.web.instance, {
          disable_api_termination = true
          instance_type           = "t2.large"
          tags = {
            backup-plan = "daily-and-weekly"
          }
        })
        user_data_cloud_init = merge(local.ec2_instances.web.user_data_cloud_init, {
          args = merge(local.ec2_instances.web.user_data_cloud_init.args, {
            branch = "main"
          })
        })
        tags = merge(local.ec2_instances.web.tags, {
          instance-scheduling  = "skip-scheduling"
          nomis-environment    = "qa11r"
          oracle-db-hostname-a = "dev-nomis-db-1-a"
          oracle-db-hostname-b = "none"
          oracle-db-name       = "qa11r"
        })
      })

    }

    iam_policies = {
      Ec2DevDatabasePolicy = {
        description = "Permissions required for Dev Database EC2s"
        statements = [
          {
            effect = "Allow"
            actions = [
              "secretsmanager:GetSecretValue",
              "secretsmanager:PutSecretValue",
            ]
            resources = [
              "arn:aws:secretsmanager:*:*:secret:/oracle/database/dev/*",
              "arn:aws:secretsmanager:*:*:secret:/oracle/database/qa11g/*",
              "arn:aws:secretsmanager:*:*:secret:/oracle/database/qa11r/*",
            ]
          }
        ]
      }
      Ec2DevWeblogicPolicy = {
        description = "Permissions required for dev Weblogic EC2s"
        statements = concat(local.iam_policy_statements_ec2.web, [
          {
            effect = "Allow"
            actions = [
              "secretsmanager:GetSecretValue",
              "secretsmanager:PutSecretValue",
            ]
            resources = [
              "arn:aws:secretsmanager:*:*:secret:/oracle/weblogic/dev/*",
              "arn:aws:secretsmanager:*:*:secret:/oracle/database/dev/weblogic-*",
            ]
          }
        ])
      }
      Ec2Qa11GWeblogicPolicy = {
        description = "Permissions required for QA11G Weblogic EC2s"
        statements = concat(local.iam_policy_statements_ec2.web, [
          {
            effect = "Allow"
            actions = [
              "secretsmanager:GetSecretValue",
              "secretsmanager:PutSecretValue",
            ]
            resources = [
              "arn:aws:secretsmanager:*:*:secret:/oracle/weblogic/qa11g/*",
              "arn:aws:secretsmanager:*:*:secret:/oracle/database/qa11g/weblogic-*",
            ]
          }
        ])
      }
      Ec2Qa11RWeblogicPolicy = {
        description = "Permissions required for QA11R Weblogic EC2s"
        statements = concat(local.iam_policy_statements_ec2.web, [
          {
            effect = "Allow"
            actions = [
              "secretsmanager:GetSecretValue",
              "secretsmanager:PutSecretValue",
            ]
            resources = [
              "arn:aws:secretsmanager:*:*:secret:/oracle/weblogic/qa11r/*",
              "arn:aws:secretsmanager:*:*:secret:/oracle/database/qa11r/weblogic-*",
            ]
          }
        ])
      }
    }

    lbs = {
      private = merge(local.lbs.private, {

        instance_target_groups = {
          dev-nomis-web-a-http-7777 = merge(local.ec2_autoscaling_groups.web.lb_target_groups.http-7777, {
            attachments = [
              { ec2_instance_name = "dev-nomis-web-a" },
            ]
          })
          qa11g-nomis-web-a-http-7777 = merge(local.ec2_autoscaling_groups.web.lb_target_groups.http-7777, {
            attachments = [
              { ec2_instance_name = "qa11g-nomis-web-a" },
            ]
          })
          qa11r-nomis-web-a-http-7777 = merge(local.ec2_autoscaling_groups.web.lb_target_groups.http-7777, {
            attachments = [
              { ec2_instance_name = "qa11r-nomis-web-a" },
            ]
          })
        }

        listeners = merge(local.lbs.private.listeners, {
          https = merge(local.lbs.private.listeners.https, {
            certificate_names_or_arns = ["nomis_wildcard_cert_v2"]

            # /home/oracle/admin/scripts/lb_maintenance_mode.sh script on
            # weblogic servers can alter priorities to enable maintenance message
            rules = {
              dev-nomis-web-a-http-7777 = {
                priority = 100
                actions = [{
                  type              = "forward"
                  target_group_name = "dev-nomis-web-a-http-7777"
                }]
                conditions = [{
                  host_header = {
                    values = [
                      "dev-nomis-web-a.development.nomis.service.justice.gov.uk",
                      "c-dev.development.nomis.service.justice.gov.uk",
                    ]
                  }
                }]
              }
              qa11g-nomis-web-a-http-7777 = {
                priority = 200
                actions = [{
                  type              = "forward"
                  target_group_name = "qa11g-nomis-web-a-http-7777"
                }]
                conditions = [{
                  host_header = {
                    values = [
                      "qa11g-nomis-web-a.development.nomis.service.justice.gov.uk",
                      "c-qa11g.development.nomis.service.justice.gov.uk",
                    ]
                  }
                }]
              }
              qa11r-nomis-web-a-http-7777 = {
                priority = 300
                actions = [{
                  type              = "forward"
                  target_group_name = "qa11r-nomis-web-a-http-7777"
                }]
                conditions = [{
                  host_header = {
                    values = [
                      "qa11r-nomis-web-a.development.nomis.service.justice.gov.uk",
                      "c-qa11r.development.nomis.service.justice.gov.uk",
                    ]
                  }
                }]
              }
              qa11g-nomis-web12-a-http-7777 = {
                priority = 500
                actions = [{
                  type              = "forward"
                  target_group_name = "qa11g-nomis-web12-a-http-7777"
                }]
                conditions = [{
                  host_header = {
                    values = [
                      "qa11g-nomis-web12-a.development.nomis.service.justice.gov.uk",
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
                    message_body = templatefile("templates/maintenance.html.tftpl", local.lb_maintenance_message_development)
                    status_code  = "200"
                  }
                }]
                conditions = [{
                  host_header = {
                    values = [
                      "maintenance.development.nomis.service.justice.gov.uk",
                      "c-dev.development.nomis.service.justice.gov.uk",
                      "c-qa11g.development.nomis.service.justice.gov.uk",
                      "c-qa11r.development.nomis.service.justice.gov.uk",
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
      "development.nomis.service.justice.gov.uk" = {
        records = [
          # SYSCON
          { name = "dev", type = "CNAME", ttl = "300", records = ["dev-nomis-db-1-a.nomis.hmpps-development.modernisation-platform.service.justice.gov.uk"] },
          { name = "qa11g", type = "CNAME", ttl = "300", records = ["dev-nomis-db-1-a.nomis.hmpps-development.modernisation-platform.service.justice.gov.uk"] },
          { name = "qa11r", type = "CNAME", ttl = "300", records = ["dev-nomis-db-1-a.nomis.hmpps-development.modernisation-platform.service.justice.gov.uk"] },
        ]
        lb_alias_records = [
          { name = "maintenance", type = "A", lbs_map_key = "private" },
          # dev
          { name = "dev-nomis-web-a", type = "A", lbs_map_key = "private" },
          { name = "dev-nomis-web-b", type = "A", lbs_map_key = "private" },
          { name = "c-dev", type = "A", lbs_map_key = "private" },
          # qa11g
          { name = "qa11g-nomis-web-a", type = "A", lbs_map_key = "private" },
          { name = "qa11g-nomis-web-b", type = "A", lbs_map_key = "private" },
          { name = "c-qa11g", type = "A", lbs_map_key = "private" },
          # qa11r
          { name = "qa11r-nomis-web-a", type = "A", lbs_map_key = "private" },
          { name = "qa11r-nomis-web-b", type = "A", lbs_map_key = "private" },
          { name = "c-qa11r", type = "A", lbs_map_key = "private" },
          # weblogic 12
          { name = "qa11g-nomis-web12-a", type = "A", lbs_map_key = "private" },
        ]
      }
    }

    s3_buckets = {
      syscon-bucket = {
        custom_kms_key = module.environment.kms_keys["general"].arn
        iam_policies   = module.baseline_presets.s3_iam_policies
        lifecycle_rule = [module.baseline_presets.s3_lifecycle_rules.software]
        tags = {
          backup = "false"
        }
      }
    }

    secretsmanager_secrets = {
      "/oracle/weblogic/dev"   = local.secretsmanager_secrets.web
      "/oracle/database/dev"   = local.secretsmanager_secrets.db_cnom
      "/oracle/weblogic/qa11g" = local.secretsmanager_secrets.web
      "/oracle/database/qa11g" = local.secretsmanager_secrets.db_cnom
      "/oracle/weblogic/qa11r" = local.secretsmanager_secrets.web
      "/oracle/database/qa11r" = local.secretsmanager_secrets.db_cnom
    }
  }
}
