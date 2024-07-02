locals {

  baseline_presets_test = {
    options = {
      sns_topics = {
        pagerduty_integrations = {
          dso_pagerduty               = "nomis_nonprod_alarms"
          dba_pagerduty               = "hmpps_shef_dba_non_prod"
          dba_high_priority_pagerduty = "hmpps_shef_dba_non_prod"
        }
      }
    }
  }

  # please keep resources in alphabetical order
  baseline_test = {

    acm_certificates = {
      nomis_combined_reporting_wildcard_cert = {
        cloudwatch_metric_alarms = module.baseline_presets.cloudwatch_metric_alarms.acm
        domain_name              = "modernisation-platform.service.justice.gov.uk"
        subject_alternate_names = [
          "*.nomis-combined-reporting.hmpps-test.modernisation-platform.service.justice.gov.uk",
        ]
        tags = {
          description = "Wildcard certificate for the test environment"
        }
      }
    }

    iam_policies = {
      Ec2T1DatabasePolicy = {
        description = "Permissions required for T1 Database EC2s"
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
              "arn:aws:secretsmanager:*:*:secret:/oracle/database/*T1/*",
              "arn:aws:secretsmanager:*:*:secret:/oracle/database/T1*/*",
            ]
          }
        ]
      }

      Ec2T1ReportingPolicy = {
        description = "Permissions required for T1 reporting EC2s"
        statements = [
          {
            effect = "Allow"
            actions = [
              "secretsmanager:GetSecretValue",
              "secretsmanager:PutSecretValue",
            ]
            resources = [
              "arn:aws:secretsmanager:*:*:secret:/ec2/ncr-bip/t1/*",
              "arn:aws:secretsmanager:*:*:secret:/ec2/ncr-web/t1/*",
            ]
          }
        ]
      }
    }

    ec2_instances = {
      t1-ncr-db-1-a = merge(local.database_ec2_default, {
        cloudwatch_metric_alarms = merge(
          local.database_cloudwatch_metric_alarms.standard,
          local.database_cloudwatch_metric_alarms.db_connected,
          local.database_cloudwatch_metric_alarms.db_backup,
        )
        config = merge(local.database_ec2_default.config, {
          instance_profile_policies = concat(local.database_ec2_default.config.instance_profile_policies, [
            "Ec2T1DatabasePolicy",
          ])
        })
        ebs_volumes = {
          "/dev/sdb" = { type = "gp3", label = "app", size = 100 }  # /u01
          "/dev/sdc" = { type = "gp3", label = "app", size = 100 }  # /u02
          "/dev/sde" = { type = "gp3", label = "data", size = 100 } # DATA01
          "/dev/sdf" = { type = "gp3", label = "data", size = 100 } # DATA02
          "/dev/sdg" = { type = "gp3", label = "data", size = 100 } # DATA03
          "/dev/sdh" = { type = "gp3", label = "data", size = 100 } # DATA04
          "/dev/sdi" = { type = "gp3", label = "data", size = 100 } # DATA05
          "/dev/sdj" = { type = "gp3", label = "flash", size = 25 } # FLASH01
          "/dev/sdk" = { type = "gp3", label = "flash", size = 25 } # FLASH02
          "/dev/sds" = { type = "gp3", label = "swap", size = 16 }
        }
        tags = merge(local.database_ec2_default.tags, {
          description                          = "T1 NCR DATABASE"
          nomis-combined-reporting-environment = "t1"
          oracle-sids                          = "T1BIPSYS T1BIPAUD"
          instance-scheduling                  = "skip-scheduling"
        })
      })

      # t1-ncr-web-1-a = merge(local.web_ec2_default, {
      #   cloudwatch_metric_alarms = local.web_cloudwatch_metric_alarms
      #   config = merge(local.web_ec2_default.config, {
      #     instance_profile_policies = concat(local.web_ec2_default.config.instance_profile_policies, [
      #       "Ec2T1ReportingPolicy",
      #     ])
      #   })
      #   instance = merge(local.web_ec2_default.instance, {
      #     vpc_security_group_ids = ["web"]
      #   })
      #   tags = merge(local.web_ec2_default.tags, {
      #     description                          = "For testing SAP BI Platform Web-Tier installation and configurations"
      #     nomis-combined-reporting-environment = "t1"
      #     type                                 = "processing"
      #     instance-scheduling                  = "skip-scheduling"
      #   })
      # })

      # t1-ncr-cms-1-a = merge(local.bip_ec2_default, {
      #   cloudwatch_metric_alarms = local.bip_cloudwatch_metric_alarms
      #   config = merge(local.bip_ec2_default.config, {
      #     instance_profile_policies = concat(local.bip_ec2_default.config.instance_profile_policies, [
      #       "Ec2T1ReportingPolicy",
      #     ])
      #   })
      #   instance = merge(local.web_ec2_default.instance, {
      #     vpc_security_group_ids = ["bip"]
      #   })
      #   tags = merge(local.bip_ec2_default.tags, {
      #     description                          = "For testing SAP BI Platform Mid-Tier installation and configurations"
      #     nomis-combined-reporting-environment = "t1"
      #     node                                 = "1"
      #     type                                 = "management"
      #     instance-scheduling                  = "skip-scheduling"
      #   })
      # })

      # t1-ncr-etl-1-a = merge(local.etl_ec2_default, {
      #   cloudwatch_metric_alarms = local.etl_cloudwatch_metric_alarms
      #   config = merge(local.etl_ec2_default.config, {
      #     instance_profile_policies = concat(local.etl_ec2_default.config.instance_profile_policies, [
      #       "Ec2T1ReportingPolicy",
      #     ])
      #   })
      #   tags = merge(local.etl_ec2_default.tags, {
      #     description                          = "For testing SAP BI Platform ETL installation and configurations"
      #     nomis-combined-reporting-environment = "t1"
      #     instance-scheduling                  = "skip-scheduling"
      #   })
      # })
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

        # instance_target_groups = {
        #   t1-ncr-web-1-a = {
        #     port     = 7777
        #     protocol = "HTTP"
        #     health_check = {
        #       enabled             = true
        #       healthy_threshold   = 3
        #       interval            = 30
        #       matcher             = "200-399"
        #       path                = "/"
        #       port                = 7777
        #       timeout             = 5
        #       unhealthy_threshold = 5
        #     }
        #     stickiness = {
        #       enabled = true
        #       type    = "lb_cookie"
        #     }
        #     attachments = [
        #       { ec2_instance_name = "t1-ncr-web-1-a" },
        #     ]
        #   }
        # }
        # listeners = {
        #   http = {
        #     port     = 7777
        #     protocol = "HTTP"
        #
        #     default_action = {
        #       type = "fixed-response"
        #       fixed_response = {
        #         content_type = "text/plain"
        #         message_body = "Not implemented"
        #         status_code  = "501"
        #       }
        #     }
        #     rules = {
        #       t1-ncr-web-1-a = {
        #         priority = 4000
        #         actions = [{
        #           type              = "forward"
        #           target_group_name = "t1-ncr-web-1-a"
        #         }]
        #         conditions = [{
        #           host_header = {
        #             values = [
        #               "t1-ncr-web-1-a.nomis-combined-reporting.hmpps-test.modernisation-platform.service.justice.gov.uk",
        #             ]
        #           }
        #         }]
        #       }
        #     }
        #   }
        #   https = {
        #     certificate_names_or_arns = ["nomis_combined_reporting_wildcard_cert"]
        #     port                      = 443
        #     protocol                  = "HTTPS"
        #     ssl_policy                = "ELBSecurityPolicy-TLS13-1-2-2021-06"
        #
        #     default_action = {
        #       type = "fixed-response"
        #       fixed_response = {
        #         content_type = "text/plain"
        #         message_body = "Not implemented"
        #         status_code  = "501"
        #       }
        #     }
        #     rules = {
        #       t1-ncr-web-1-a = {
        #         priority = 4580
        #         actions = [{
        #           type              = "forward"
        #           target_group_name = "t1-ncr-web-1-a"
        #         }]
        #         conditions = [{
        #           host_header = {
        #             values = [
        #               "t1-ncr-web-1-a.nomis-combined-reporting.hmpps-test.modernisation-platform.service.justice.gov.uk",
        #             ]
        #           }
        #         }]
        #       }
        #     }
        #   }
        # }
      }
    }

    route53_zones = {
      "test.reporting.nomis.service.justice.gov.uk" = {
        records = [
          { name = "db", type = "CNAME", ttl = "3600", records = ["t1-ncr-db-1-a.nomis-combined-reporting.hmpps-test.modernisation-platform.service.justice.gov.uk"] },
          { name = "web", type = "CNAME", ttl = "3600", records = ["t1-ncr-web-1-a.nomis-combined-reporting.hmpps-test.modernisation-platform.service.justice.gov.uk"] },
          { name = "etl", type = "CNAME", ttl = "3600", records = ["t1-ncr-etl-1-a.nomis-combined-reporting.hmpps-test.modernisation-platform.service.justice.gov.uk"] }
        ]
      }
    }

    s3_buckets = {
      nomis-combined-reporting-bip-packages = {
        bucket_policy_v2 = [
          module.baseline_presets.s3_bucket_policies.AllEnvironmentsReadOnlyAccessBucketPolicy
        ]
        custom_kms_key = module.environment.kms_keys["general"].arn
        iam_policies   = module.baseline_presets.s3_iam_policies
        lifecycle_rule = [module.baseline_presets.s3_lifecycle_rules.software]
        tags = {
          backup = "false"
        }
      }
    }

    secretsmanager_secrets = {
      "/ec2/ncr-bip/t1" = local.bip_secretsmanager_secrets
      "/ec2/ncr-web/t1" = local.web_secretsmanager_secrets

      "/oracle/database/T1BIPSYS" = local.database_secretsmanager_secrets
      "/oracle/database/T1BIPAUD" = local.database_secretsmanager_secrets
    }
  }
}
