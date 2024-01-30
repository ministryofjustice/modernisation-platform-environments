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
        external_validation_records_created = true
        cloudwatch_metric_alarms            = module.baseline_presets.cloudwatch_metric_alarms.acm
        tags = {
          description = "Wildcard certificate for the ${local.environment} environment"
        }
      }
    }

    baseline_secretsmanager_secrets = {
      "/ec2/ncr-bip-cms/t1"      = local.bip_cms_secretsmanager_secrets
      "/ec2/ncr-tomcat-admin/t1" = local.tomcat_admin_secretsmanager_secrets

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
              "arn:aws:secretsmanager:*:*:secret:/ec2/ncr-bip-cms/t1/*",
              "arn:aws:secretsmanager:*:*:secret:/ec2/ncr-tomcat-admin/t1/*",
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
    }

    baseline_ec2_autoscaling_groups = {

      t1-ncr-tomcat-admin-a = merge(local.tomcat_admin_ec2_default, {
        autoscaling_group = {
          desired_capacity    = 0
          max_size            = 1
          vpc_zone_identifier = module.environment.subnets["private"].ids
        }
        cloudwatch_metric_alarms = local.tomcat_admin_cloudwatch_metric_alarms
        config = merge(local.tomcat_admin_ec2_default.config, {
          instance_profile_policies = concat(local.tomcat_admin_ec2_default.config.instance_profile_policies, [
            "Ec2T1ReportingPolicy",
          ])
        })
        tags = merge(local.tomcat_admin_ec2_default.tags, {
          description                          = "For testing SAP BI Platform tomcat admin installation and configurations"
          nomis-combined-reporting-environment = "t1"
          deployment                           = "blue"
        })
      })
      t1-ncr-tomcat-admin-b = merge(local.tomcat_admin_ec2_default, {
        autoscaling_group = {
          desired_capacity    = 0
          max_size            = 1
          vpc_zone_identifier = module.environment.subnets["private"].ids
        }
        cloudwatch_metric_alarms = local.tomcat_admin_cloudwatch_metric_alarms
        config = merge(local.tomcat_admin_ec2_default.config, {
          instance_profile_policies = concat(local.tomcat_admin_ec2_default.config.instance_profile_policies, [
            "Ec2T1ReportingPolicy",
          ])
        })
        tags = merge(local.tomcat_admin_ec2_default.tags, {
          description                          = "For testing SAP BI Platform tomcat admin installation and configurations"
          nomis-combined-reporting-environment = "t1"
          deployment                           = "green"
        })
      })
      t1-ncr-bip-cms-a = merge(local.bip_cms_ec2_default, {
        autoscaling_group = {
          desired_capacity    = 0
          max_size            = 1
          vpc_zone_identifier = module.environment.subnets["private"].ids
        }
        cloudwatch_metric_alarms = local.bip_cms_cloudwatch_metric_alarms
        config = merge(local.bip_cms_ec2_default.config, {
          instance_profile_policies = concat(local.bip_cms_ec2_default.config.instance_profile_policies, [
            "Ec2T1ReportingPolicy",
          ])
        })
        tags = merge(local.bip_cms_ec2_default.tags, {
          description                          = "For testing SAP BI Platform CMS installation and configurations"
          nomis-combined-reporting-environment = "t1"
          deployment                           = "blue"
        })
      })
      t1-ncr-bip-cms-b = merge(local.bip_cms_ec2_default, {
        autoscaling_group = {
          desired_capacity    = 0
          max_size            = 1
          vpc_zone_identifier = module.environment.subnets["private"].ids
        }
        cloudwatch_metric_alarms = local.bip_cms_cloudwatch_metric_alarms
        config = merge(local.bip_cms_ec2_default.config, {
          instance_profile_policies = concat(local.bip_cms_ec2_default.config.instance_profile_policies, [
            "Ec2T1ReportingPolicy",
          ])
        })
        tags = merge(local.bip_cms_ec2_default.tags, {
          description                          = "For testing SAP BI Platform CMS installation and configurations"
          nomis-combined-reporting-environment = "t1"
          deployment                           = "green"
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
          http = merge(local.bip_cms_lb_listeners.http, local.tomcat_admin_lb_listeners.http)

          http7777 = merge(local.bip_cms_lb_listeners.http7777, local.tomcat_admin_lb_listeners.http7777, {
            rules = {
              t1-ncr-bip-cms-a = {
                priority = 100
                actions = [{
                  type              = "forward"
                  target_group_name = "t1-ncr-bip-cms-a-http-7777"
                }]
                conditions = [{
                  host_header = {
                    values = [
                      "t1-ncr-bip-cms.test.reporting.nomis.service.justice.gov.uk",
                    ]
                  }
                }]
              }
              t1-ncr-bip-cms-b = {
                priority = 200
                actions = [{
                  type              = "forward"
                  target_group_name = "t1-ncr-bip-cms-b-http-7777"
                }]
                conditions = [{
                  host_header = {
                    values = [
                      "t1-ncr-bip-cms-b.test.reporting.nomis.service.justice.gov.uk",
                    ]
                  }
                }]
              }
              t1-ncr-tomcat-admin-a = {
                priority = 300
                actions = [{
                  type              = "forward"
                  target_group_name = "t1-ncr-tomcat-admin-a-http-7777"
                }]
                conditions = [{
                  host_header = {
                    values = [
                      "t1-ncr-tomcat-admin-a.test.reporting.nomis.service.justice.gov.uk",
                    ]
                  }
                }]
              }
              t1-ncr-tomcat-admin-b = {
                priority = 400
                actions = [{
                  type              = "forward"
                  target_group_name = "t1-ncr-tomcat-admin-b-http-7777"
                }]
                conditions = [{
                  host_header = {
                    values = [
                      "t1-ncr-tomcat-admin-b.test.reporting.nomis.service.justice.gov.uk",
                    ]
                  }
                }]
              }
            }
          })
          http6455 = merge(local.bip_cms_lb_listeners.http6455, {
            rules = {
              t1-ncr-bip-cms-a = {
                priority = 100
                actions = [{
                  type              = "forward"
                  target_group_name = "t1-ncr-bip-cms-a-http-6455"
                }]
                conditions = [{
                  host_header = {
                    values = [
                      "t1-ncr-bip-cms-a.test.reporting.nomis.service.justice.gov.uk",
                    ]
                  }
                }]
              }
              t1-ncr-bip-cms-b = {
                priority = 200
                actions = [{
                  type              = "forward"
                  target_group_name = "t1-ncr-bip-cms-b-http-6455"
                }]
                conditions = [{
                  host_header = {
                    values = [
                      "t1-ncr-bip-cms-b.test.reporting.nomis.service.justice.gov.uk",
                    ]
                  }
                }]
              }
            }
          })
          http6410 = merge(local.bip_cms_lb_listeners.http6410, {
            rules = {
              t1-ncr-bip-cms-a = {
                priority = 100
                actions = [{
                  type              = "forward"
                  target_group_name = "t1-ncr-bip-cms-a-http-6410"
                }]
                conditions = [{
                  host_header = {
                    values = [
                      "t1-ncr-bip-cms-a.test.reporting.nomis.service.justice.gov.uk",
                    ]
                  }
                }]
              }
              t1-ncr-bip-cms-b = {
                priority = 200
                actions = [{
                  type              = "forward"
                  target_group_name = "t1-ncr-bip-cms-b-http-6410"
                }]
                conditions = [{
                  host_header = {
                    values = [
                      "t1-ncr-bip-cms-b.test.reporting.nomis.service.justice.gov.uk",
                    ]
                  }
                }]
              }
            }
          })
          http6400 = merge(local.bip_cms_lb_listeners.http6400, {
            rules = {
              t1-ncr-bip-cms-a = {
                priority = 100
                actions = [{
                  type              = "forward"
                  target_group_name = "t1-ncr-bip-cms-a-http-6400"
                }]
                conditions = [{
                  host_header = {
                    values = [
                      "t1-ncr-bip-cms-a.test.reporting.nomis.service.justice.gov.uk",
                    ]
                  }
                }]
              }
              t1-ncr-bip-cms-b = {
                priority = 200
                actions = [{
                  type              = "forward"
                  target_group_name = "t1-ncr-bip-cms-b-http-6400"
                }]
                conditions = [{
                  host_header = {
                    values = [
                      "t1-ncr-bip-cms-b.test.reporting.nomis.service.justice.gov.uk",
                    ]
                  }
                }]
              }
            }
          })
          http7010 = merge(local.tomcat_admin_lb_listeners.http7010, {
            rules = {
              t1-ncr-tomcat-admin-a = {
                priority = 100
                actions = [{
                  type              = "forward"
                  target_group_name = "t1-ncr-tomcat-admin-a-http-7010"
                }]
                conditions = [{
                  host_header = {
                    values = [
                      "t1-ncr-tomcat-admin-a.test.reporting.nomis.service.justice.gov.uk",
                    ]
                  }
                }]
              }
              t1-ncr-tomcat-admin-b = {
                priority = 200
                actions = [{
                  type              = "forward"
                  target_group_name = "t1-ncr-tomcat-admin-b-http-7010"
                }]
                conditions = [{
                  host_header = {
                    values = [
                      "t1-ncr-tomcat-admin-b.test.reporting.nomis.service.justice.gov.uk",
                    ]
                  }
                }]
              }
            }
          })
          http8005 = merge(local.tomcat_admin_lb_listeners.http8005, {
            rules = {
              t1-ncr-tomcat-admin-a = {
                priority = 100
                actions = [{
                  type              = "forward"
                  target_group_name = "t1-ncr-tomcat-admin-a-http-8005"
                }]
                conditions = [{
                  host_header = {
                    values = [
                      "t1-ncr-tomcat-admin-a.test.reporting.nomis.service.justice.gov.uk",
                    ]
                  }
                }]
              }
              t1-ncr-tomcat-admin-b = {
                priority = 200
                actions = [{
                  type              = "forward"
                  target_group_name = "t1-ncr-tomcat-admin-b-http-8005"
                }]
                conditions = [{
                  host_header = {
                    values = [
                      "t1-ncr-tomcat-admin-b.test.reporting.nomis.service.justice.gov.uk",
                    ]
                  }
                }]
              }
            }
          })
          http8443 = merge(local.tomcat_admin_lb_listeners.http8443, {
            rules = {
              t1-ncr-tomcat-admin-a = {
                priority = 100
                actions = [{
                  type              = "forward"
                  target_group_name = "t1-ncr-tomcat-admin-a-http-8443"
                }]
                conditions = [{
                  host_header = {
                    values = [
                      "t1-ncr-tomcat-admin-a.test.reporting.nomis.service.justice.gov.uk",
                    ]
                  }
                }]
              }
              t1-ncr-tomcat-admin-b = {
                priority = 200
                actions = [{
                  type              = "forward"
                  target_group_name = "t1-ncr-tomcat-admin-b-http-8443"
                }]
                conditions = [{
                  host_header = {
                    values = [
                      "t1-ncr-tomcat-admin-b.test.reporting.nomis.service.justice.gov.uk",
                    ]
                  }
                }]
              }
            }
          })
          https = merge(local.bip_cms_lb_listeners.https, local.tomcat_admin_lb_listeners.https, {
            rules = {
              t1-ncr-bip-cms-a-http-7777 = {
                priority = 100
                actions = [{
                  type              = "forward"
                  target_group_name = "t1-ncr-bip-cms-a-http-7777"
                }]
                conditions = [{
                  host_header = {
                    values = [
                      "t1-ncr-bip-cms-a.test.reporting.nomis.service.justice.gov.uk",
                    ]
                  }
                }]
              }
              t1-ncr-bip-cms-b-http-7777 = {
                priority = 150
                actions = [{
                  type              = "forward"
                  target_group_name = "t1-ncr-bip-cms-b-http-7777"
                }]
                conditions = [{
                  host_header = {
                    values = [
                      "t1-ncr-bip-cms-b.test.reporting.nomis.service.justice.gov.uk",
                    ]
                  }
                }]
              }
              t1-ncr-tomcat-admin-a-http-7777 = {
                priority = 500
                actions = [{
                  type              = "forward"
                  target_group_name = "t1-ncr-tomcat-admin-a-http-7777"
                }]
                conditions = [{
                  host_header = {
                    values = [
                      "t1-ncr-tomcat-admin-a.test.reporting.nomis.service.justice.gov.uk",
                    ]
                  }
                }]
              }
              t1-ncr-tomcat-admin-b-http-7777 = {
                priority = 550
                actions = [{
                  type              = "forward"
                  target_group_name = "t1-ncr-tomcat-admin-b-http-7777"
                }]
                conditions = [{
                  host_header = {
                    values = [
                      "t1-ncr-tomcat-admin-b.test.reporting.nomis.service.justice.gov.uk",
                    ]
                  }
                }]
              }
            }
          })
        }
      }
    }
    baseline_route53_zones = {
      "test.reporting.nomis.service.justice.gov.uk" = {
        records = [
          { name = "t1-ncr", type = "CNAME", ttl = "300", records = ["t1ncr-a.test.reporting.nomis.service.justice.gov.uk"] },
          { name = "t1-ncr-a", type = "CNAME", ttl = "300", records = ["t1-ncr-db-1-a.nomis-combined-reporting.hmpps-test.modernisation-platform.service.justice.gov.uk"] },
          { name = "t1-ncr-b", type = "CNAME", ttl = "300", records = ["t1-ncr-db-1-b.nomis-combined-reporting.hmpps-test.modernisation-platform.service.justice.gov.uk"] },
        ]
        lb_alias_records = [
          # T1
          { name = "t1-ncr-bip-cms-a", type = "A", lbs_map_key = "private" },
          { name = "t1-ncr-bip-cms-b", type = "A", lbs_map_key = "private" },
          { name = "t1-ncr-tomcat-admin-a", type = "A", lbs_map_key = "private" },
          { name = "t1-ncr-tomcat-admin-b", type = "A", lbs_map_key = "private" },
        ]
      }
    }
  }
}
