locals {
  preproduction_config = {
    baseline_s3_buckets = {
      ncr-db-backup-bucket = {
        custom_kms_key = module.environment.kms_keys["general"].arn
        iam_policies   = module.baseline_presets.s3_iam_policies
      }
    }
    baseline_acm_certificates = {
      nomis_combined_reporting_wildcard_cert = {
        domain_name = module.environment.domains.public.modernisation_platform
        subject_alternate_names = [
          "*.${module.environment.domains.public.application_environment}",
        ]
        external_validation_records_created = true
        cloudwatch_metric_alarms            = module.baseline_presets.cloudwatch_metric_alarms.acm
        tags = {
          description = "Wildcard certificate for the ${local.environment} environment"
        }
      }
    }
    baseline_secretsmanager_secrets = {
      "/ec2/ncr-bip/pp"           = local.bip_secretsmanager_secrets
      "/ec2/ncr-web/pp"           = local.web_secretsmanager_secrets
      "/ec2/ncr-bip/lsast"        = local.bip_secretsmanager_secrets
      "/ec2/ncr-web/lsast"        = local.web_secretsmanager_secrets
      "/oracle/database/PPBIPSYS" = local.database_secretsmanager_secrets
      "/oracle/database/PPBIPAUD" = local.database_secretsmanager_secrets
    }

    baseline_efs = {
      bip = {
        access_points = {
          root = {
            posix_user = {
              gid = 10003 # binstall
              uid = 10003 # bobj
            }
            root_directory = {
              path = "/"
              creation_info = {
                owner_gid   = 10003 # binstall
                owner_uid   = 10003 # bobj
                permissions = "0777"
              }
            }
          }
        }
        backup_policy_status = "DISABLED"
        file_system = {
          availability_zone_name = "eu-west-2a"
          lifecycle_policy = {
            transition_to_ia = "AFTER_30_DAYS"
          }
        }
        mount_targets = [{
          subnet_name        = "private"
          availability_zones = ["eu-west-2a"]
          security_groups    = ["private"]
        }]
      }
    }

    baseline_iam_policies = {
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
              "arn:aws:secretsmanager:*:*:secret:/oracle/database/*lsast/*",
              "arn:aws:secretsmanager:*:*:secret:/oracle/database/lsast*/*",
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
    }
    baseline_ec2_instances = {

      ### PREPROD

      pp-ncr-cms-a = merge(local.bip_ec2_default, {
        cloudwatch_metric_alarms = local.bip_cloudwatch_metric_alarms
        config = merge(local.bip_ec2_default.config, {
          availability_zone = "${local.region}a"
          instance_profile_policies = concat(local.bip_ec2_default.config.instance_profile_policies, [
            "Ec2PPReportingPolicy",
          ])
        })
        instance = merge(local.bip_ec2_default.instance, {
          instance_type = "c5.4xlarge",
        })
        tags = merge(local.bip_ec2_default.tags, {
          description                          = "PreProd SAP BI Platform CMS installation and configurations"
          nomis-combined-reporting-environment = "pp"
          type                                 = "management"
          node                                 = "1"
          instance-scheduling                  = "skip-scheduling"
        })
      })
      pp-ncr-cms-b = merge(local.bip_ec2_default, {
        cloudwatch_metric_alarms = local.bip_cloudwatch_metric_alarms
        config = merge(local.bip_ec2_default.config, {
          availability_zone = "${local.region}b"
          instance_profile_policies = concat(local.bip_ec2_default.config.instance_profile_policies, [
            "Ec2PPReportingPolicy",
          ])
        })
        instance = merge(local.bip_ec2_default.instance, {
          instance_type = "c5.4xlarge",
        })
        tags = merge(local.bip_ec2_default.tags, {
          description                          = "PreProd SAP BI Platform CMS installation and configurations"
          nomis-combined-reporting-environment = "pp"
          type                                 = "management"
          node                                 = "2"
          instance-scheduling                  = "skip-scheduling"
        })
      })
      pp-ncr-processing-1-a = merge(local.bip_ec2_default, {
        cloudwatch_metric_alarms = local.bip_cloudwatch_metric_alarms
        config = merge(local.bip_ec2_default.config, {
          availability_zone = "${local.region}a"
          instance_profile_policies = concat(local.bip_ec2_default.config.instance_profile_policies, [
            "Ec2PPReportingPolicy",
          ])
        })
        instance = merge(local.bip_ec2_default.instance, {
          instance_type = "c5.4xlarge",
        })
        tags = merge(local.bip_ec2_default.tags, {
          description                          = "PreProd SAP BI Platform installation and configurations"
          nomis-combined-reporting-environment = "pp"
          type                                 = "processing"
          node                                 = "3"
          instance-scheduling                  = "skip-scheduling"
        })
      })
      pp-ncr-web-admin-a = merge(local.web_ec2_default, {
        cloudwatch_metric_alarms = local.web_cloudwatch_metric_alarms
        config = merge(local.web_ec2_default.config, {
          availability_zone = "${local.region}a"
          instance_profile_policies = concat(local.web_ec2_default.config.instance_profile_policies, [
            "Ec2PPReportingPolicy",
          ])
        })
        instance = merge(local.web_ec2_default.instance, {
          instance_type = "r7i.large",
        })
        tags = merge(local.web_ec2_default.tags, {
          description                          = "PreProd SAP BI Platform web-tier admin installation and configurations"
          nomis-combined-reporting-environment = "pp"
          instance-scheduling                  = "skip-scheduling"
        })
      })
      pp-ncr-web-1-a = merge(local.web_ec2_default, {
        cloudwatch_metric_alarms = local.web_cloudwatch_metric_alarms
        config = merge(local.web_ec2_default.config, {
          availability_zone = "${local.region}a"
          instance_profile_policies = concat(local.web_ec2_default.config.instance_profile_policies, [
            "Ec2PPReportingPolicy",
          ])
        })
        instance = merge(local.web_ec2_default.instance, {
          instance_type = "r7i.large",
        })
        tags = merge(local.web_ec2_default.tags, {
          description                          = "PreProd SAP BI Platform web-tier installation and configurations"
          nomis-combined-reporting-environment = "pp"
          instance-scheduling                  = "skip-scheduling"
        })
      })
      pp-ncr-web-2-b = merge(local.web_ec2_default, {
        cloudwatch_metric_alarms = local.web_cloudwatch_metric_alarms
        config = merge(local.web_ec2_default.config, {
          availability_zone = "${local.region}b"
          instance_profile_policies = concat(local.web_ec2_default.config.instance_profile_policies, [
            "Ec2PPReportingPolicy",
          ])
        })
        instance = merge(local.web_ec2_default.instance, {
          instance_type = "r7i.xlarge",
        })
        tags = merge(local.web_ec2_default.tags, {
          description                          = "PreProd SAP BI Platform web-tier installation and configurations"
          nomis-combined-reporting-environment = "pp"
          instance-scheduling                  = "skip-scheduling"
        })
      })
      pp-ncr-etl-a = merge(local.etl_ec2_default, {
        cloudwatch_metric_alarms = local.etl_cloudwatch_metric_alarms
        config = merge(local.etl_ec2_default.config, {
          instance_profile_policies = concat(local.etl_ec2_default.config.instance_profile_policies, [
            "Ec2PPReportingPolicy",
          ])
        })
        tags = merge(local.etl_ec2_default.tags, {
          description                          = "PreProd SAP BI Platform ETL installation and configurations"
          nomis-combined-reporting-environment = "pp"
          instance-scheduling                  = "skip-scheduling"
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
        ebs_volumes = {
          "/dev/sdb" = { # /u01
            size  = 100
            label = "app"
            type  = "gp3"
          }
          "/dev/sdc" = { # /u02
            size  = 500
            label = "app"
            type  = "gp3"
          }
          "/dev/sde" = { # DATA01
            label = "data"
            size  = 500
            type  = "gp3"
          }
          "/dev/sdj" = { # FLASH01
            label = "flash"
            type  = "gp3"
            size  = 200
          }
          "/dev/sds" = {
            label = "swap"
            type  = "gp3"
            size  = 4
          }
        }
        ebs_volume_config = {
          data = {
            iops       = 3000 # min 3000
            type       = "gp3"
            throughput = 125
            total_size = 500
          }
          flash = {
            iops       = 3000 # min 3000
            type       = "gp3"
            throughput = 125
            total_size = 200
          }
        }
        tags = merge(local.database_ec2_default.tags, {
          description                          = "PREPROD NCR DATABASE"
          nomis-combined-reporting-environment = "pp"
          oracle-sids                          = "PPBIPSYS PPBIPAUD"
          instance-scheduling                  = "skip-scheduling"
        })
      })

      ### LSAST

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

      # lsast-ncr-db-1-a = merge(local.database_ec2_default, {
      #   cloudwatch_metric_alarms = merge(
      #     local.database_cloudwatch_metric_alarms.standard,
      #     local.database_cloudwatch_metric_alarms.db_connected,
      #     local.database_cloudwatch_metric_alarms.db_backup,
      #   )
      #   config = merge(local.database_ec2_default.config, {
      #     instance_profile_policies = concat(local.database_ec2_default.config.instance_profile_policies, [
      #       "Ec2LSASTDatabasePolicy",
      #     ])
      #   })
      #   tags = merge(local.database_ec2_default.tags, {
      #     description                          = "LSAST NCR DATABASE"
      #     nomis-combined-reporting-environment = "lsast"
      #     oracle-sids                          = "LSASTBIPSYS LSASTBIPAUD"
      #     instance-scheduling                  = "skip-scheduling"
      #   })
      # })

    }
    baseline_lbs = {
      private = {
        internal_lb                      = true
        enable_delete_protection         = false
        load_balancer_type               = "application"
        idle_timeout                     = 3600
        security_groups                  = ["private"]
        subnets                          = module.environment.subnets["private"].ids
        enable_cross_zone_load_balancing = true

        instance_target_groups = {
          pp-ncr-web = {
            port     = 7777
            protocol = "HTTP"
            health_check = {
              enabled             = true
              path                = "/"
              healthy_threshold   = 3
              unhealthy_threshold = 5
              timeout             = 5
              interval            = 30
              matcher             = "200-399"
              port                = 7777
            }
            stickiness = {
              enabled = true
              type    = "lb_cookie"
            }
            attachments = [
              { ec2_instance_name = "pp-ncr-web-admin-a" },
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
            port                      = 443
            protocol                  = "HTTPS"
            ssl_policy                = "ELBSecurityPolicy-2016-08"
            certificate_names_or_arns = ["nomis_combined_reporting_wildcard_cert"]
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
                      "pp.nomis-combined-reporting.hmpps-preproduction.modernisation-platform.service.justice.gov.uk",
                    ]
                  }
                }]
              }
            }
          }
        }
      }
    }
    baseline_route53_zones = {
      "preproduction.reporting.nomis.service.justice.gov.uk" = {
        records = [
          { name = "db", type = "CNAME", ttl = "3600", records = ["pp-ncr-db-1-a.nomis-combined-reporting.hmpps-preproduction.modernisation-platform.service.justice.gov.uk"] },
          { name = "admin", type = "CNAME", ttl = "3600", records = ["pp-ncr-web-admin-a.nomis-combined-reporting.hmpps-preproduction.modernisation-platform.service.justice.gov.uk"] },
        ]
        lb_alias_records = [
          { name = "pp", type = "A", lbs_map_key = "private" },
        ]
      }
    }
  }
}
