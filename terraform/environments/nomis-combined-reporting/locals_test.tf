locals {
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
        tags = {
          description = "Wildcard certificate for the ${local.environment} environment"
        }
      }
    }

    baseline_ssm_parameters = {
      # T1
      "t1-ncr-tomcat"  = local.tomcat_ssm_parameters
      "t1-ncr-bip"     = local.bip_ssm_parameters
      "t1-ncr-bip-cmc" = local.bip_cmc_ssm_parameters

      "/oracle/database/T1BIPSYS" = local.database_ssm_parameters
      "/oracle/database/T1BIPAUD" = local.database_ssm_parameters
    }

    baseline_secretsmanager_secrets = {
      "/t1-ncr-bip-cmc" = local.bip_cmc_secretsmanager_secrets
      "/t1-ncr-bip"     = local.bip_secretsmanager_secrets
      "/t1-ncr-tomcat"  = local.tomcat_secretsmanager_secrets

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
      Ec2T1BipPolicy = {
        description = "Permissions required for T1 Weblogic EC2s"
        statements = [
          {
            effect = "Allow"
            actions = [
              "secretsmanager:GetSecretValue",
            ]
            resources = [
              "arn:aws:secretsmanager:*:*:secret:/t1-ncr-bip-cmc/*",
              "arn:aws:secretsmanager:*:*:secret:/t1-ncr-bip/*",
              "arn:aws:secretsmanager:*:*:secret:/t1-ncr-tomcat/*",
            ]
          }
        ]
      }
    }

    baseline_ec2_instances = {
      t1-ncr-bip-cmc = merge(local.bip_cmc_ec2_default, {
        config = merge(local.bip_cmc_ec2_default.config, {
          instance_profile_policies = concat(local.bip_cmc_ec2_default.config.instance_profile_policies, [
            "Ec2T1BipPolicy",
          ])
        })
        tags = merge(local.bip_cmc_ec2_default.tags, {
          description                          = "For testing SAP BI CMC installation and configurations"
          nomis-combined-reporting-environment = "t1"
        })
      })
      t1-ncr-db-1-a = merge(local.database_ec2_default, {
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
    }

    baseline_ec2_autoscaling_groups = {

      t1-ncr-tomcat = merge(local.tomcat_ec2_default, {
        autoscaling_group = {
          desired_capacity    = 1
          max_size            = 2
          vpc_zone_identifier = module.environment.subnets["private"].ids
        }
        config = merge(local.tomcat_ec2_default.config, {
          instance_profile_policies = concat(local.tomcat_ec2_default.config.instance_profile_policies, [
            "Ec2T1BipPolicy",
          ])
        })
        tags = merge(local.tomcat_ec2_default.tags, {
          description                          = "For testing BIP tomcat installation and configurations"
          nomis-combined-reporting-environment = "t1"
        })
      })

      t1-ncr-bip = merge(local.bip_ec2_default, {
        autoscaling_group = {
          desired_capacity    = 1
          max_size            = 2
          vpc_zone_identifier = module.environment.subnets["private"].ids
        }
        config = merge(local.bip_ec2_default.config, {
          instance_profile_policies = concat(local.bip_ec2_default.config.instance_profile_policies, [
            "Ec2T1BipPolicy",
          ])
        })
        tags = merge(local.bip_ec2_default.tags, {
          description                          = "For testing BIP 4.3 installation and configurations"
          nomis-combined-reporting-environment = "t1"
        })
      })
    }
    baseline_lbs = {
      private = {
        internal_lb              = true
        enable_delete_protection = false
        force_destrroy_bucket    = true
        idle_timeout             = 3600
        subnets                  = module.environment.subnets["private"].ids
        security_groups          = ["private"]
        listeners = {
          http = {
            port     = 80
            protocol = "HTTP"
            default_action = {
              type = "redirect"
              redirect = {
                port        = "443"
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
                message_body = "HTTPS"
                status_code  = "200"
              }
            }
          }
        }
      }
    }
    baseline_route53_zones = {
      "test.reporting.nomis.service.justice.gov.uk" = {
        records = [
          # T1 BIP
          { name = "t1-ncr-bip-cmc", type = "CNAME", ttl = "300", records = ["t1-ncr-bip-cmc.nomis.hmpps-test.modernisation-platform.service.justice.gov.uk"] },
          { name = "t1-ncr-bip", type = "CNAME", ttl = "300", records = ["t1-ncr-bip.nomis.hmpps-test.modernisation-platform.service.justice.gov.uk"] },
          # T1 Tomcat
          { name = "t1-ncr-tomcat", type = "CNAME", ttl = "300", records = ["t1-ncr-tomcat.nomis.hmpps-test.modernisation-platform.service.justice.gov.uk"] },
          # Oracle database
          { name = "t1-ncr", type = "CNAME", ttl = "300", records = ["t1ncr-a.test.reporting.nomis.service.justice.gov.uk"] },
          { name = "t1-ncr-a", type = "CNAME", ttl = "300", records = ["t1-ncr-db-1-a.nomis-combined-reporting.hmpps-test.modernisation-platform.service.justice.gov.uk"] },
          { name = "t1-ncr-b", type = "CNAME", ttl = "300", records = ["t1-ncr-db-1-b.nomis-combined-reporting.hmpps-test.modernisation-platform.service.justice.gov.uk"] },
        ]
        lb_alias_records = [
          # T1
          { name = "t1-ncr-bip-cmc", type = "A", lbs_map_key = "private" },
          { name = "t1-ncr-bip", type = "A", lbs_map_key = "private" },
          { name = "t1-ncr-tomcat", type = "A", lbs_map_key = "private" },
        ]
      }
    }
  }
}
