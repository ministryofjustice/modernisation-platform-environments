locals {

  baseline_presets_preproduction = {
    options = {
      sns_topics = {
        pagerduty_integrations = {
          dso_pagerduty               = "nomis_alarms"
          dba_pagerduty               = "hmpps_shef_dba_low_priority"
          dba_high_priority_pagerduty = "hmpps_shef_dba_low_priority"
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
          security_groups    = ["bip"]
        }]
        tags = {
          backup = "false"
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

    ec2_instances = {
      # lsast-ncr-cms-1 = merge(local.bip_ec2_default, {
      #   cloudwatch_metric_alarms = local.bip_cloudwatch_metric_alarms
      #   config = merge(local.bip_ec2_default.config, {
      #     instance_profile_policies = concat(local.bip_ec2_default.config.instance_profile_policies, [
      #       "Ec2LSASTReportingPolicy",
      #     ])
      #   })
      #   instance = merge(local.bip_ec2_default.instance, {
      #     instance_type = "c5.4xlarge",
      #   })
      #   tags = merge(local.bip_ec2_default.tags, {
      #     description                          = "LSAST SAP BI Platform CMS installation and configurations"
      #     nomis-combined-reporting-environment = "lsast"
      #     node                                 = "1"
      #   })
      # })

      ls-ncr-db-1-a = merge(local.database_ec2_default, {
        #cloudwatch_metric_alarms = merge(
        #  local.database_cloudwatch_metric_alarms.standard,
        #  local.database_cloudwatch_metric_alarms.db_connected,
        #  local.database_cloudwatch_metric_alarms.db_backup,
        #)
        config = merge(local.database_ec2_default.config, {
          instance_profile_policies = concat(local.database_ec2_default.config.instance_profile_policies, [
            "Ec2LSASTDatabasePolicy",
          ])
        })
        tags = merge(local.database_ec2_default.tags, {
          description                          = "LSAST NCR DATABASE"
          nomis-combined-reporting-environment = "lsast"
          oracle-sids                          = ""
          instance-scheduling                  = "skip-scheduling"
        })
      })

      # lsast-ncr-web-1 = merge(local.web_ec2_default, {
      #   cloudwatch_metric_alarms = local.web_cloudwatch_metric_alarms
      #   config = merge(local.web_ec2_default.config, {
      #     instance_profile_policies = concat(local.web_ec2_default.config.instance_profile_policies, [
      #       "Ec2LSASTReportingPolicy",
      #     ])
      #   })
      #   instance = merge(local.web_ec2_default.instance, {
      #     instance_type = "r7i.xlarge",
      #   })
      #   tags = merge(local.web_ec2_default.tags, {
      #     description                          = "LSAST SAP BI Platform tomcat installation and configurations"
      #     nomis-combined-reporting-environment = "lsast"
      #   })
      # })

      pp-ncr-cms-a = merge(local.bip_ec2_default, {
        #cloudwatch_metric_alarms = local.bip_cloudwatch_metric_alarms # comment in when commissioned
        config = merge(local.bip_ec2_default.config, {
          ami_name          = "base_rhel_8_5_2024-05-01T00-00-19.643Z"
          availability_zone = "eu-west-2a"
          instance_profile_policies = concat(local.bip_ec2_default.config.instance_profile_policies, [
            "Ec2PPReportingPolicy",
          ])
        })
        instance = merge(local.bip_ec2_default.instance, {
          instance_type = "m6i.xlarge",
        })
        tags = merge(local.bip_ec2_default.tags, {
          description                          = "PreProd SAP BI Platform CMS installation and configurations"
          instance-scheduling                  = "skip-scheduling"
          node                                 = "1"
          nomis-combined-reporting-environment = "pp"
          type                                 = "management"
        })
      })

      pp-ncr-cms-b = merge(local.bip_ec2_default, {
        #cloudwatch_metric_alarms = local.bip_cloudwatch_metric_alarms # comment in when commissioned
        config = merge(local.bip_ec2_default.config, {
          ami_name          = "base_rhel_8_5_2024-05-01T00-00-19.643Z"
          availability_zone = "eu-west-2b"
          instance_profile_policies = concat(local.bip_ec2_default.config.instance_profile_policies, [
            "Ec2PPReportingPolicy",
          ])
        })
        instance = merge(local.bip_ec2_default.instance, {
          instance_type = "m6i.xlarge",
        })
        tags = merge(local.bip_ec2_default.tags, {
          description                          = "PreProd SAP BI Platform CMS installation and configurations"
          instance-scheduling                  = "skip-scheduling"
          node                                 = "2"
          nomis-combined-reporting-environment = "pp"
          type                                 = "management"
        })
      })

      pp-ncr-db-1-a = merge(local.database_ec2_default, {
        cloudwatch_metric_alarms = merge(
          local.database_cloudwatch_metric_alarms.standard,
          local.database_cloudwatch_metric_alarms.db_connected,
          local.database_cloudwatch_metric_alarms.db_backup,
        )
        config = merge(local.database_ec2_default.config, {
          instance_profile_policies = concat(local.database_ec2_default.config.instance_profile_policies, [
            "Ec2PPDatabasePolicy",
          ])
        })
        tags = merge(local.database_ec2_default.tags, {
          description                          = "PREPROD NCR DATABASE"
          nomis-combined-reporting-environment = "pp"
          oracle-sids                          = "PPBIPSYS PPBIPAUD"
          instance-scheduling                  = "skip-scheduling"
        })
      })

      # pp-ncr-client-a = merge(local.jumpserver_ec2_default, {
      #   # cloudwatch_metric_alarms = local.client_cloudwatch_metric_alarms # comment in when commissioned
      #   config = merge(local.jumpserver_ec2_default.config, {
      #     ami_name          = "hmpps_windows_server_2019_release_2024-05-02T00-00-37.552Z"
      #     availability_zone = "eu-west-2a"
      #     instance_profile_policies = concat(local.jumpserver_ec2_default.config.instance_profile_policies, [
      #       "Ec2PPReportingPolicy",
      #     ])
      #   })
      #   instance = merge(local.jumpserver_ec2_default.instance, {
      #     instance_type = "t3.large",
      #   })
      #   tags = merge(local.jumpserver_ec2_default.tags, {
      #     description                          = "PreProd Jumpserver and Client Tools"
      #     instance-scheduling                  = "skip-scheduling"
      #     nomis-combined-reporting-environment = "pp"
      #   })
      # })

      pp-ncr-etl-a = merge(local.etl_ec2_default, {
        # cloudwatch_metric_alarms = local.etl_cloudwatch_metric_alarms # comment in when commissioned
        config = merge(local.etl_ec2_default.config, {
          ami_name = "hmpps_windows_server_2019_release_2024-05-02T00-00-37.552Z"
          instance_profile_policies = concat(local.etl_ec2_default.config.instance_profile_policies, [
            "Ec2PPReportingPolicy",
          ])
        })
        instance = merge(local.etl_ec2_default.instance, {
          instance_type = "m6i.2xlarge",
        })
        tags = merge(local.etl_ec2_default.tags, {
          description                          = "PreProd SAP BI Platform ETL installation and configurations"
          instance-scheduling                  = "skip-scheduling"
          nomis-combined-reporting-environment = "pp"
        })
      })

      pp-ncr-processing-1-a = merge(local.bip_ec2_default, {
        # cloudwatch_metric_alarms = local.bip_cloudwatch_metric_alarms # comment in when commissioned
        config = merge(local.bip_ec2_default.config, {
          ami_name          = "base_rhel_8_5_2024-05-01T00-00-19.643Z"
          availability_zone = "eu-west-2a"
          instance_profile_policies = concat(local.bip_ec2_default.config.instance_profile_policies, [
            "Ec2PPReportingPolicy",
          ])
        })
        instance = merge(local.bip_ec2_default.instance, {
          instance_type = "m6i.4xlarge",
        })
        tags = merge(local.bip_ec2_default.tags, {
          description                          = "PreProd SAP BI Platform installation and configurations"
          instance-scheduling                  = "skip-scheduling"
          node                                 = "3"
          nomis-combined-reporting-environment = "pp"
          type                                 = "processing"
        })
      })

      pp-ncr-web-1-a = merge(local.web_ec2_default, {
        # cloudwatch_metric_alarms = local.web_cloudwatch_metric_alarms # comment in when commissioned
        config = merge(local.web_ec2_default.config, {
          ami_name          = "base_rhel_8_5_2024-05-01T00-00-19.643Z"
          availability_zone = "eu-west-2a"
          instance_profile_policies = concat(local.web_ec2_default.config.instance_profile_policies, [
            "Ec2PPReportingPolicy",
          ])
        })
        instance = merge(local.web_ec2_default.instance, {
          instance_type = "r6i.xlarge",
        })
        tags = merge(local.web_ec2_default.tags, {
          description                          = "PreProd SAP BI Platform web-tier installation and configurations"
          instance-scheduling                  = "skip-scheduling"
          nomis-combined-reporting-environment = "pp"
        })
      })

      pp-ncr-web-2-b = merge(local.web_ec2_default, {
        # cloudwatch_metric_alarms = local.web_cloudwatch_metric_alarms # comment in when commissioned
        config = merge(local.web_ec2_default.config, {
          ami_name          = "base_rhel_8_5_2024-05-01T00-00-19.643Z"
          availability_zone = "eu-west-2b"
          instance_profile_policies = concat(local.web_ec2_default.config.instance_profile_policies, [
            "Ec2PPReportingPolicy",
          ])
        })
        instance = merge(local.web_ec2_default.instance, {
          instance_type = "r6i.xlarge",
        })
        tags = merge(local.web_ec2_default.tags, {
          description                          = "PreProd SAP BI Platform web-tier installation and configurations"
          instance-scheduling                  = "skip-scheduling"
          nomis-combined-reporting-environment = "pp"
        })
      })

      pp-ncr-web-admin-a = merge(local.web_ec2_default, {
        # cloudwatch_metric_alarms = local.web_cloudwatch_metric_alarms # comment in when commissioned
        config = merge(local.web_ec2_default.config, {
          ami_name          = "base_rhel_8_5_2024-05-01T00-00-19.643Z"
          availability_zone = "eu-west-2a"
          instance_profile_policies = concat(local.web_ec2_default.config.instance_profile_policies, [
            "Ec2PPReportingPolicy",
          ])
        })
        instance = merge(local.web_ec2_default.instance, {
          instance_type = "r6i.large",
        })
        tags = merge(local.web_ec2_default.tags, {
          description                          = "PreProd SAP BI Platform web-tier admin installation and configurations"
          instance-scheduling                  = "skip-scheduling"
          nomis-combined-reporting-environment = "pp"
        })
      })
    }

    lbs = {
      private = {
        enable_cross_zone_load_balancing = true
        enable_delete_protection         = false
        idle_timeout                     = 3600
        internal_lb                      = true
        load_balancer_type               = "application"
        security_groups                  = ["lb"]
        subnets                          = module.environment.subnets["private"].ids

        instance_target_groups = {
          pp-ncr-web = {
            port     = 7777
            protocol = "HTTP"
            health_check = {
              enabled             = true
              healthy_threshold   = 3
              interval            = 30
              matcher             = "200-399"
              path                = "/"
              port                = 7777
              timeout             = 5
              unhealthy_threshold = 5
            }
            stickiness = {
              enabled = true
              type    = "lb_cookie"
            }
            attachments = [
              { ec2_instance_name = "pp-ncr-web-1-a" },
              { ec2_instance_name = "pp-ncr-web-2-b" },
            ]
          }
        }
        listeners = {
          http = {
            port     = 80
            protocol = "HTTP"

            default_action = {
              type = "redirect"
              redirect = {
                port        = 443
                protocol    = "HTTPS"
                status_code = "HTTP_301"
              }
            }
          }
          https = {
            certificate_names_or_arns = ["nomis_combined_reporting_wildcard_cert"]
            port                      = 443
            protocol                  = "HTTPS"
            ssl_policy                = "ELBSecurityPolicy-2016-08"

            default_action = {
              type = "fixed-response"
              fixed_response = {
                content_type = "text/plain"
                message_body = "Not implemented"
                status_code  = "501"
              }
            }
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
          }
        }
      }
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
          { name = "", type = "A", lbs_map_key = "private" }, # preproduction.reporting.nomis.service.justice.gov.uk
        ]
      }
    }

    s3_buckets = {
      ncr-db-backup-bucket = {
        custom_kms_key = module.environment.kms_keys["general"].arn
        iam_policies   = module.baseline_presets.s3_iam_policies
      }
    }

    secretsmanager_secrets = {
      "/ec2/ncr-bip/pp"           = local.bip_secretsmanager_secrets
      "/ec2/ncr-web/pp"           = local.web_secretsmanager_secrets
      "/ec2/ncr-bip/lsast"        = local.bip_secretsmanager_secrets
      "/ec2/ncr-web/lsast"        = local.web_secretsmanager_secrets
      "/oracle/database/PPBIPSYS" = local.database_secretsmanager_secrets
      "/oracle/database/PPBIPAUD" = local.database_secretsmanager_secrets
      "/oracle/database/PPBISYS"  = local.database_secretsmanager_secrets
      "/oracle/database/PPBIAUD"  = local.database_secretsmanager_secrets
      "/oracle/database/LSBIPSYS" = local.database_secretsmanager_secrets
      "/oracle/database/LSBIPAUD" = local.database_secretsmanager_secrets
      "/oracle/database/LSBISYS"  = local.database_secretsmanager_secrets
      "/oracle/database/LSBIAUD"  = local.database_secretsmanager_secrets
    }
  }
}
