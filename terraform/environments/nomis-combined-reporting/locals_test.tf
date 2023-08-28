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
      "t1-ncr-tomcat" = local.tomcat_ssm_parameters
      "t1-ncr-bip"    = local.bip_ssm_parameters
    }

    baseline_ec2_instances = {
      t1-ncr-bip-cmc = merge(local.bi-platform_ec2_default, {
        tags = merge(local.bi-platform_ec2_default.tags, {
          description                          = "For testing SAP BI CMC installation and configurations"
          server-type                          = "ncr-bip-cmc"
          nomis-combined-reporting-environment = "t1"
        })
      })
      t1-ncr-db-1-a = merge(local.database_ec2_default, {
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
        tags = merge(local.tomcat_ec2_default.tags, {
          description                          = "For testing SAP tomcat installation and configurations"
          nomis-combined-reporting-environment = "t1"
        })
      })

      t1-ncr-biplatform = merge(local.bi-platform_ec2_default, {
        autoscaling_group = {
          desired_capacity    = 0
          max_size            = 2
          vpc_zone_identifier = module.environment.subnets["private"].ids
        }
        tags = merge(local.bi-platform_ec2_default.tags, {
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
        public_subnets           = module.environment.subnets["private"].ids
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

          # T1 Tomcat

          # Oracle database
          { name = "t1ncr", type = "CNAME", ttl = "300", records = ["t1ncr-a.test.reporting.nomis.service.justice.gov.uk"] },
          { name = "t1ncr-a", type = "CNAME", ttl = "300", records = ["t1-ncr-db-1-a.nomis-combined-reporting.hmpps-test.modernisation-platform.service.justice.gov.uk"] },
          { name = "t1ncr-b", type = "CNAME", ttl = "300", records = ["t1-ncr-db-1-b.nomis-combined-reporting.hmpps-test.modernisation-platform.service.justice.gov.uk"] },
        ]
      }
    }
  }
}
