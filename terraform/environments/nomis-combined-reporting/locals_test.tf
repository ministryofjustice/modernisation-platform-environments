locals {

  # baseline presets config
  test_baseline_presets_options = {
    sns_topics = {
      pagerduty_integrations = {
        dso_pagerduty               = "nomis_nonprod_alarms"
        dba_pagerduty               = "hmpps_shef_dba_non_prod"
        dba_high_priority_pagerduty = "hmpps_shef_dba_non_prod"
      }
    }
  }

  test_config = {

    baseline_s3_buckets = {

      # the shared image builder bucket is just created in test
      nomis-combined-reporting-software = {
        custom_kms_key = module.environment.kms_keys["general"].arn
        bucket_policy_v2 = [
          module.baseline_presets.s3_bucket_policies.ImageBuilderWriteAccessBucketPolicy,
          module.baseline_presets.s3_bucket_policies.AllEnvironmentsWriteAccessBucketPolicy
        ]
        iam_policies = module.baseline_presets.s3_iam_policies
      }
      nomis-combined-reporting-bip-packages = {
        custom_kms_key = module.environment.kms_keys["general"].arn
        bucket_policy_v2 = [
          module.baseline_presets.s3_bucket_policies.AllEnvironmentsReadOnlyAccessBucketPolicy
        ]
        iam_policies = module.baseline_presets.s3_iam_policies
      }
      ncr-db-backup-bucket = {
        custom_kms_key = module.environment.kms_keys["general"].arn
        bucket_policy_v2 = [
          module.baseline_presets.s3_bucket_policies.DevTestEnvironmentsReadOnlyAccessBucketPolicy,
        ]
        iam_policies = module.baseline_presets.s3_iam_policies
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
      "/ec2/ncr-bip/t1" = local.bip_secretsmanager_secrets
      "/ec2/ncr-web/t1" = local.web_secretsmanager_secrets

      "/oracle/database/T1BIPSYS" = local.database_secretsmanager_secrets
      "/oracle/database/T1BIPAUD" = local.database_secretsmanager_secrets
    }

    baseline_iam_policies = {
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

    baseline_ec2_instances = {
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
        tags = merge(local.database_ec2_default.tags, {
          description                          = "T1 NCR DATABASE"
          nomis-combined-reporting-environment = "t1"
          oracle-sids                          = "T1BIPSYS T1BIPAUD"
          instance-scheduling                  = "skip-scheduling"
        })
      })
      t1-ncr-web-1-a = merge(local.web_ec2_default, {
        cloudwatch_metric_alarms = local.web_cloudwatch_metric_alarms
        config = merge(local.web_ec2_default.config, {
          instance_profile_policies = concat(local.web_ec2_default.config.instance_profile_policies, [
            "Ec2T1ReportingPolicy",
          ])
        })
        instance = merge(local.web_ec2_default.instance, {
          vpc_security_group_ids = ["web"]
        })
        tags = merge(local.web_ec2_default.tags, {
          description                          = "For testing SAP BI Platform Web-Tier installation and configurations"
          nomis-combined-reporting-environment = "t1"
          type                                 = "processing"
          instance-scheduling                  = "skip-scheduling"
        })
      })
      t1-ncr-cms-1-a = merge(local.bip_ec2_default, {
        cloudwatch_metric_alarms = local.bip_cloudwatch_metric_alarms
        config = merge(local.bip_ec2_default.config, {
          instance_profile_policies = concat(local.bip_ec2_default.config.instance_profile_policies, [
            "Ec2T1ReportingPolicy",
          ])
        })
        instance = merge(local.web_ec2_default.instance, {
          vpc_security_group_ids = ["bip"]
        })
        tags = merge(local.bip_ec2_default.tags, {
          description                          = "For testing SAP BI Platform Mid-Tier installation and configurations"
          nomis-combined-reporting-environment = "t1"
          node                                 = "1"
          type                                 = "management"
          instance-scheduling                  = "skip-scheduling"
        })
      })
      t1-ncr-etl-1-a = merge(local.etl_ec2_default, {
        cloudwatch_metric_alarms = local.etl_cloudwatch_metric_alarms
        config = merge(local.etl_ec2_default.config, {
          instance_profile_policies = concat(local.etl_ec2_default.config.instance_profile_policies, [
            "Ec2T1ReportingPolicy",
          ])
        })
        tags = merge(local.etl_ec2_default.tags, {
          description                          = "For testing SAP BI Platform ETL installation and configurations"
          nomis-combined-reporting-environment = "t1"
          instance-scheduling                  = "skip-scheduling"
        })
      })
    }
    baseline_lbs = {
      private = {
        internal_lb                      = true
        enable_delete_protection         = false
        load_balancer_type               = "application"
        idle_timeout                     = 3600
        security_groups                  = ["lb"]
        subnets                          = module.environment.subnets["private"].ids
        enable_cross_zone_load_balancing = true

        instance_target_groups = {
          t1-ncr-web-1-a = {
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
              { ec2_instance_name = "t1-ncr-web-1-a" },
            ]
          }
        }
        listeners = {
          http = {
            port     = 7777
            protocol = "HTTP"
            default_action = {
              type = "fixed-response"
              fixed_response = {
                content_type = "text/plain"
                message_body = "Not implemented"
                status_code  = "501"
              }
            }
            rules = {
              t1-ncr-web-1-a = {
                priority = 4000
                actions = [{
                  type              = "forward"
                  target_group_name = "t1-ncr-web-1-a"
                }]
                conditions = [{
                  host_header = {
                    values = [
                      "t1-ncr-web-1-a.nomis-combined-reporting.hmpps-test.modernisation-platform.service.justice.gov.uk",
                    ]
                  }
                }]
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
              t1-ncr-web-1-a = {
                priority = 4580
                actions = [{
                  type              = "forward"
                  target_group_name = "t1-ncr-web-1-a"
                }]
                conditions = [{
                  host_header = {
                    values = [
                      "t1-ncr-web-1-a.nomis-combined-reporting.hmpps-test.modernisation-platform.service.justice.gov.uk",
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
      "test.reporting.nomis.service.justice.gov.uk" = {
        records = [
          { name = "db", type = "CNAME", ttl = "3600", records = ["t1-ncr-db-1-a.nomis-combined-reporting.hmpps-test.modernisation-platform.service.justice.gov.uk"] },
          { name = "web", type = "CNAME", ttl = "3600", records = ["t1-ncr-web-1-a.nomis-combined-reporting.hmpps-test.modernisation-platform.service.justice.gov.uk"] },
          { name = "etl", type = "CNAME", ttl = "3600", records = ["t1-ncr-etl-1-a.nomis-combined-reporting.hmpps-test.modernisation-platform.service.justice.gov.uk"] }
        ]
      }
    }
  }
}
