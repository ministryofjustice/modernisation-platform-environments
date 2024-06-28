locals {

  baseline_presets_test = {
    options = {
      enable_observability_platform_monitoring = true
      sns_topics = {
        pagerduty_integrations = {
          dso_pagerduty               = "oasys_nonprod_alarms"
          dba_pagerduty               = "hmpps_shef_dba_non_prod"
          dba_high_priority_pagerduty = "hmpps_shef_dba_non_prod"
        }
      }
    }
  }

  # please keep resources in alphabetical order
  baseline_test = {

    acm_certificates = {
      t2_oasys_cert = {
        cloudwatch_metric_alarms            = module.baseline_presets.cloudwatch_metric_alarms.acm
        domain_name                         = "t2.oasys.service.justice.gov.uk"
        external_validation_records_created = true
        subject_alternate_names = [
          "*.oasys.service.justice.gov.uk",
          "*.hmpp-azdt.justice.gov.uk",
          "ords.t2.oasys.service.justice.gov.uk",
          "ords.t1.oasys.service.justice.gov.uk",
        ]
        tags = {
          description = "cert for t2 oasys test domains"
        }
      }
    }

    cloudwatch_log_groups = {
      session-manager-logs     = { retention_in_days = 7 }
      cwagent-var-log-messages = { retention_in_days = 7 }
      cwagent-var-log-secure   = { retention_in_days = 7 }
      cwagent-windows-system   = { retention_in_days = 7 }
      cwagent-oasys-autologoff = { retention_in_days = 7 }
      cwagent-web-logs         = { retention_in_days = 7 }
    }

    iam_policies = {
      Ec2T1BipPolicy = {
        description = "Permissions required for T1 Bip EC2s"
        statements = [
          {
            effect = "Allow"
            actions = [
              "secretsmanager:GetSecretValue",
            ]
            resources = [
              "arn:aws:secretsmanager:*:*:secret:/oracle/bip/t1/*",
              "arn:aws:secretsmanager:*:*:secret:/oracle/database/*T1/bip-*",
              "arn:aws:secretsmanager:*:*:secret:/oracle/database/T1*/bip-*",
            ]
          }
        ]
      }
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
      Ec2T1WebPolicy = {
        description = "Permissions required for T1 Web EC2s"
        statements = [
          {
            effect = "Allow"
            actions = [
              "secretsmanager:GetSecretValue",
            ]
            resources = [
              "arn:aws:secretsmanager:*:*:secret:/oracle/database/T1OASYS/apex-passwords*",
            ]
          }
        ]
      }

      Ec2T2BipPolicy = {
        description = "Permissions required for T2 Bip EC2s"
        statements = [
          {
            effect = "Allow"
            actions = [
              "secretsmanager:GetSecretValue",
            ]
            resources = [
              "arn:aws:secretsmanager:*:*:secret:/oracle/bip/t2/*",
              "arn:aws:secretsmanager:*:*:secret:/oracle/database/*T2/bip-*",
              "arn:aws:secretsmanager:*:*:secret:/oracle/database/T2*/bip-*",
            ]
          }
        ]
      }
      Ec2T2DatabasePolicy = {
        description = "Permissions required for T2 Database EC2s"
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
              "arn:aws:secretsmanager:*:*:secret:/oracle/database/*T2/*",
              "arn:aws:secretsmanager:*:*:secret:/oracle/database/T2*/*",
            ]
          }
        ]
      }
      Ec2T2WebPolicy = {
        description = "Permissions required for T2 Web EC2s"
        statements = [
          {
            effect = "Allow"
            actions = [
              "secretsmanager:GetSecretValue",
            ]
            resources = [
              "arn:aws:secretsmanager:*:*:secret:/oracle/database/T2OASYS/apex-passwords*",
            ]
          }
        ]
      }

      Ec2AuditVaultPolicy = {
        description = "Permissions required for Audit vault ec2"
        statements = [
          {
            effect = "Allow"
            actions = [
              "s3:GetObject",
              "s3:GetObjectTagging",
              "s3:ListBucket",
            ]
            resources = [
              "arn:aws:s3:::s3-bucket*",
              "arn:aws:s3:::s3-bucket*/*",
            ]
          }
        ]
      }
    }

    ec2_autoscaling_groups = {
      t1-oasys-web-a = merge(local.webserver, {
        autoscaling_schedules = {
          scale_up   = { recurrence = "0 5 * * Mon-Fri" }
          scale_down = { desired_capacity = 0, recurrence = "0 19 * * Mon-Fri" }
        }
        config = merge(module.baseline_presets.ec2_instance.config.default, {
          ami_name                  = "oasys_webserver_release_*"
          iam_resource_names_prefix = "ec2-web-t1"
          instance_profile_policies = concat(local.webserver.config.instance_profile_policies, [
            "Ec2T1WebPolicy",
          ])
          ssm_parameters_prefix = "ec2-web-t1/"
        })
        tags = merge(local.webserver.tags, {
          description        = "t1 oasys web"
          oasys-environment  = "t1"
          oracle-db-hostname = "db.t1.oasys.hmpps-test.modernisation-platform.internal"
          oracle-db-sid      = "T1OASYS" # for each env using azure DB will need to be OASPROD
        })
      })

      t2-oasys-web-a = merge(local.webserver, {
        autoscaling_schedules = {
          scale_up   = { recurrence = "0 5 * * Mon-Fri" }
          scale_down = { desired_capacity = 0, recurrence = "0 19 * * Mon-Fri" }
        }
        config = merge(module.baseline_presets.ec2_instance.config.default, {
          ami_name                  = "oasys_webserver_release_*"
          iam_resource_names_prefix = "ec2-web-t2"
          instance_profile_policies = concat(local.webserver.config.instance_profile_policies, [
            "Ec2T2WebPolicy",
          ])
          ssm_parameters_prefix = "ec2-web-t2/"
        })
        tags = merge(local.webserver.tags, {
          description        = "t2 oasys web"
          oasys-environment  = "t2"
          oracle-db-hostname = "db.t2.oasys.hmpps-test.modernisation-platform.internal"
          oracle-db-sid      = "T2OASYS" # for each env using azure DB will need to be OASPROD
        })
      })
    }

    ec2_instances = {
      audit-vault = merge(local.audit_vault, {
        config = merge(local.audit_vault.config, {
          instance_profile_policies = concat(local.audit_vault.config.instance_profile_policies, [
            "Ec2AuditVaultPolicy",
          ])
        })
        ebs_volumes = {
          # "/dev/sdb" = { label = "app", snapshot_id = "snap-072a42704cb38f785", size = 300 }
          "/dev/sdb" = { label = "app", size = 300 }
        }
        instance = merge(local.audit_vault.instance, {
          instance_type = "r6i.xlarge"
        })
        tags = merge(local.audit_vault.tags, {
          instance-scheduling = "skip-scheduling"
        })
      })

      t1-oasys-bip-a = merge(local.bip_a, {
        config = merge(local.bip_a.config, {
          instance_profile_policies = concat(local.bip_a.config.instance_profile_policies, [
            "Ec2T1BipPolicy",
          ])
        })
        user_data_cloud_init = merge(local.bip_a.user_data_cloud_init, {
          args = merge(local.bip_a.user_data_cloud_init.args, {
            branch = "main"
          })
        })
        tags = merge(local.bip_a.tags, {
          bip-db-hostname   = "t1-oasys-db-a"
          bip-db-name       = "T1BIPINF"
          oasys-db-hostname = "t1-oasys-db-a"
          oasys-db-name     = "T1OASYS"
          oasys-environment = "t1"
        })
      })

      t1-oasys-db-a = merge(local.database_a, {
        config = merge(local.database_a.config, {
          instance_profile_policies = concat(local.database_a.config.instance_profile_policies, [
            "Ec2T1DatabasePolicy",
          ])
        })
        ebs_volumes = {
          "/dev/sdb" = { label = "app", size = 100 } # /u01
          "/dev/sdc" = { label = "app", size = 500 } # /u02
          "/dev/sde" = { label = "data", size = 500 }
          "/dev/sdf" = { label = "data", size = 50 }
          "/dev/sdj" = { label = "flash", size = 50 }
          "/dev/sds" = { label = "swap", size = 2 }
        }
        instance = merge(local.database_a.instance, {
          instance_type = "r6i.xlarge"
        })
        tags = merge(local.database_a.tags, {
          bip-db-name         = "T1BIPINF"
          description         = "t1 oasys database"
          instance-scheduling = "skip-scheduling"
          oasys-environment   = "t1"
          oracle-sids         = "T1BIPINF T1MISTRN T1OASREP T1OASYS T1ONRAUD T1ONRBDS T1ONRSYS"
        })
      })

      t2-oasys-bip-a = merge(local.bip_a, {
        config = merge(local.bip_a.config, {
          instance_profile_policies = concat(local.bip_a.config.instance_profile_policies, [
            "Ec2T2BipPolicy",
          ])
        })
        user_data_cloud_init = merge(local.bip_a.user_data_cloud_init, {
          args = merge(local.bip_a.user_data_cloud_init.args, {
            branch = "main"
          })
        })
        tags = merge(local.bip_a.tags, {
          bip-db-hostname   = "t2-oasys-db-a"
          bip-db-name       = "T2BIPINF"
          oasys-db-hostname = "t2-oasys-db-a"
          oasys-db-name     = "T2OASYS"
          oasys-environment = "t2"
        })
      })

      t2-oasys-db-a = merge(local.database_a, {
        config = merge(local.database_a.config, {
          instance_profile_policies = concat(local.database_a.config.instance_profile_policies, [
            "Ec2T2DatabasePolicy",
          ])
        })
        ebs_volumes = {
          "/dev/sdb" = { label = "app", size = 100 } # /u01
          "/dev/sdc" = { label = "app", size = 500 } # /u02
          "/dev/sde" = { label = "data", size = 500, iops = 12000, throughput = 750 }
          "/dev/sdf" = { label = "data", size = 50 }
          "/dev/sdj" = { label = "flash", size = 50, iops = 5000, throughput = 500 }
          "/dev/sds" = { label = "swap", size = 2 }
        }
        instance = merge(local.database_a.instance, {
          instance_type = "r6i.xlarge"
        })
        tags = merge(local.database_a.tags, {
          bip-db-name         = "T2BIPINF"
          description         = "t2 oasys database"
          instance-scheduling = "skip-scheduling"
          oasys-environment   = "t2"
          oracle-sids         = "T2BIPINF T2MISTRN T2OASREP T2OASYS T2ONRAUD T2ONRBDS T2ONRSYS"
        })
      })

      t2-onr-db-a = merge(local.database_onr_a, {
        config = merge(local.database_onr_a.config, {
          instance_profile_policies = concat(local.database_onr_a.config.instance_profile_policies, [
            "Ec2T2DatabasePolicy",
          ])
        })
        ebs_volumes = {
          "/dev/sdb" = { label = "app", size = 100 } # /u01
          "/dev/sdc" = { label = "app", size = 500 } # /u02
          "/dev/sde" = { label = "data", size = 2000 }
          "/dev/sdj" = { label = "flash", size = 600 }
          "/dev/sds" = { label = "swap", size = 2 }
        }
        instance = merge(local.database_onr_a.instance, {
          instance_type = "r6i.xlarge"
        })
        tags = merge(local.database_onr_a.tags, {
          instance-scheduling = "skip-scheduling"
          oasys-environment   = "test"             # should be T2
          oracle-sids         = "OASPROD BIPINFRA" # should be T2BOSYS T2BOAUD
        })
      })
    }

    # options for LBs https://docs.google.com/presentation/d/1RpXpfNY_hw7FjoMw0sdMAdQOF7kZqLUY6qVVtLNavWI/edit?usp=sharing
    lbs = {
      public = {
        access_logs              = true
        enable_delete_protection = false
        idle_timeout             = 3600 # 60 is default
        internal_lb              = false
        force_destroy_bucket     = true
        security_groups          = ["public_lb"]
        subnets                  = module.environment.subnets["public"].ids
        tags                     = local.tags

        listeners = {
          https = {
            certificate_names_or_arns = ["t2_oasys_cert"]
            port                      = 443
            protocol                  = "HTTPS"
            ssl_policy                = "ELBSecurityPolicy-TLS13-1-2-2021-06"

            default_action = {
              type = "fixed-response"
              fixed_response = {
                content_type = "text/plain"
                message_body = "T2 - use t2.oasys.service.justice.gov.uk, T1 - use t1.oasys.service.justice.gov.uk"
                status_code  = "200"
              }
            }

            rules = {
              t2-web-http-8080 = {
                priority = 100
                actions = [{
                  type              = "forward"
                  target_group_name = "t2-oasys-web-a-pb-http-8080"
                }]
                conditions = [
                  {
                    host_header = {
                      values = [
                        "t2.oasys.service.justice.gov.uk",
                        "t2-a.oasys.service.justice.gov.uk",
                        "ords.t2.oasys.service.justice.gov.uk",
                      ]
                    }
                  }
                ]
              }
              t1-web-http-8080 = {
                priority = 300
                actions = [{
                  type              = "forward"
                  target_group_name = "t1-oasys-web-a-pb-http-8080"
                }]
                conditions = [
                  {
                    host_header = {
                      values = [
                        "t1.oasys.service.justice.gov.uk",
                        "t1-a.oasys.service.justice.gov.uk",
                        "ords.t1.oasys.service.justice.gov.uk",
                      ]
                    }
                  }
                ]
              }
            }
          }
        }
      }
      private = {
        access_logs              = true
        enable_delete_protection = false
        force_destroy_bucket     = true
        idle_timeout             = 3600 # 60 is default
        internal_lb              = true
        security_groups          = ["private_lb"]
        subnets                  = module.environment.subnets["private"].ids
        tags                     = local.tags

        listeners = {
          https = {
            certificate_names_or_arns = ["t2_oasys_cert"]
            port                      = 443
            protocol                  = "HTTPS"
            ssl_policy                = "ELBSecurityPolicy-TLS13-1-2-2021-06"

            default_action = {
              type = "fixed-response"
              fixed_response = {
                content_type = "text/plain"
                message_body = "T2 - use t2-int.oasys.service.justice.gov.uk, T1 - use t1-int.oasys.service.justice.gov.uk"
                status_code  = "200"
              }
            }

            rules = {
              t2-web-http-8080 = {
                priority = 100
                actions = [{
                  type              = "forward"
                  target_group_name = "t2-oasys-web-a-pv-http-8080"
                }]
                conditions = [
                  {
                    host_header = {
                      values = [
                        "t2-int.oasys.service.justice.gov.uk",
                        "t2-a-int.oasys.service.justice.gov.uk",
                        "t2-oasys.hmpp-azdt.justice.gov.uk",
                      ]
                    }
                  }
                ]
              }
              t1-web-http-8080 = {
                priority = 300
                actions = [{
                  type              = "forward"
                  target_group_name = "t1-oasys-web-a-pv-http-8080"
                }]
                conditions = [
                  {
                    host_header = {
                      values = [
                        "t1-int.oasys.service.justice.gov.uk",
                        "t1-a-int.oasys.service.justice.gov.uk",
                        "t1-oasys.hmpp-azdt.justice.gov.uk",
                      ]
                    }
                  }
                ]
              }
            }
          }
        }
      }
    }

    route53_zones = {
      "hmpps-test.modernisation-platform.service.justice.gov.uk" = {
        records = [
          { name = "db.t2.oasys", type = "CNAME", ttl = "3600", records = ["t2-oasys-db-a.oasys.hmpps-test.modernisation-platform.service.justice.gov.uk"] },
          { name = "db.t1.oasys", type = "CNAME", ttl = "3600", records = ["t1-oasys-db-a.oasys.hmpps-test.modernisation-platform.service.justice.gov.uk"] },
        ]
      }
      "hmpps-test.modernisation-platform.internal" = {
        vpc = { # this makes it a private hosted zone
          id = module.environment.vpc.id
        }
        records = [
          { name = "db.t2.oasys", type = "CNAME", ttl = "3600", records = ["t2-oasys-db-a.oasys.hmpps-test.modernisation-platform.internal"] },
          { name = "db.t1.oasys", type = "CNAME", ttl = "3600", records = ["t1-oasys-db-a.oasys.hmpps-test.modernisation-platform.internal"] },
        ]
      }
    }

    secretsmanager_secrets = {
      "/oracle/bip/t1" = local.secretsmanager_secrets_bip
      "/oracle/bip/t2" = local.secretsmanager_secrets_bip

      "/oracle/database/T1OASYS"  = local.secretsmanager_secrets_oasys_db
      "/oracle/database/T1OASREP" = local.secretsmanager_secrets_db
      "/oracle/database/T1AZBIPI" = local.secretsmanager_secrets_bip_db
      "/oracle/database/T1BIPINF" = local.secretsmanager_secrets_bip_db
      "/oracle/database/T1MISTRN" = local.secretsmanager_secrets_db
      "/oracle/database/T1ONRSYS" = local.secretsmanager_secrets_db
      "/oracle/database/T1ONRAUD" = local.secretsmanager_secrets_db
      "/oracle/database/T1ONRBDS" = local.secretsmanager_secrets_db

      "/oracle/database/T2OASYS"  = local.secretsmanager_secrets_oasys_db
      "/oracle/database/T2OASREP" = local.secretsmanager_secrets_db
      "/oracle/database/T2AZBIPI" = local.secretsmanager_secrets_bip_db
      "/oracle/database/T2BIPINF" = local.secretsmanager_secrets_bip_db
      "/oracle/database/T2MISTRN" = local.secretsmanager_secrets_db
      "/oracle/database/T2ONRSYS" = local.secretsmanager_secrets_db
      "/oracle/database/T2ONRAUD" = local.secretsmanager_secrets_db
      "/oracle/database/T2ONRBDS" = local.secretsmanager_secrets_db

      "/oracle/database/T2BOSYS" = local.secretsmanager_secrets_bip_db
      "/oracle/database/T2BOAUD" = local.secretsmanager_secrets_bip_db
    }
  }
}
