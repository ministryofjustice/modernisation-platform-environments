locals {

  baseline_presets_preproduction = {
    options = {
      sns_topics = {
        pagerduty_integrations = {
          dso_pagerduty               = "oasys_alarms"
          dba_pagerduty               = "hmpps_shef_dba_low_priority"
          dba_high_priority_pagerduty = "hmpps_shef_dba_low_priority"
        }
      }
    }
  }

  # please keep resources in alphabetical order
  baseline_preproduction = {

    # If your DNS records are in Fix 'n' Go, setup will be a 2 step process, see the acm_certificate module readme
    # if making changes, comment out the listeners that use the cert, edit the cert, recreate the listeners
    acm_certificates = {
      pp_oasys_cert = {
        cloudwatch_metric_alarms            = module.baseline_presets.cloudwatch_metric_alarms.acm
        domain_name                         = "pp.oasys.service.justice.gov.uk"
        external_validation_records_created = true
        subject_alternate_names = [
          "pp-int.oasys.service.justice.gov.uk",
          "bridge-pp-oasys.az.justice.gov.uk",
          "pp-oasys.az.justice.gov.uk",
          "*.pp-oasys.az.justice.gov.uk",
        ]
        tags = {
          description = "cert for oasys preproduction domains"
        }
      }
    }

    cloudwatch_log_groups = {
      session-manager-logs     = { retention_in_days = 14 }
      cwagent-var-log-messages = { retention_in_days = 14 }
      cwagent-var-log-secure   = { retention_in_days = 14 }
      cwagent-windows-system   = { retention_in_days = 14 }
      cwagent-oasys-autologoff = { retention_in_days = 14 }
      cwagent-web-logs         = { retention_in_days = 14 }
    }

    ec2_autoscaling_groups = {
      pp-oasys-web-a = merge(local.webserver, {
        autoscaling_schedules = {
          scale_up   = { recurrence = "0 5 * * Mon-Fri" }
          scale_down = { desired_capacity = 0, recurrence = "0 19 * * Mon-Fri" }
        }
        config = merge(local.webserver.config, {
          ami_name                  = "oasys_webserver_release_*"
          iam_resource_names_prefix = "ec2-web-pp"
          instance_profile_policies = concat(local.webserver.config.instance_profile_policies, [
            "Ec2PreprodWebPolicy",
          ])
          ssm_parameters_prefix = "ec2-web-pp/"
        })
        tags = merge(local.webserver.tags, {
          oracle-db-hostname = "db.pp.oasys.hmpps-preproduction.modernisation-platform.internal"
          oracle-db-sid      = "PPOASYS" # "OASPROD"
          oasys-environment  = "preproduction"
        })
      })
    }

    ec2_instances = {
      pp-oasys-db-a = merge(local.database_a, {
        config = merge(local.database_a.config, {
          instance_profile_policies = concat(local.database_a.config.instance_profile_policies, [
            "Ec2PreprodDatabasePolicy",
          ])
        })
        ebs_volumes = {
          "/dev/sdb" = { label = "app", size = 100 }  # /u01
          "/dev/sdc" = { label = "app", size = 1000 } # /u02
          "/dev/sde" = { label = "data", size = 2000 }
          "/dev/sdf" = { label = "data", size = 2000 }
          "/dev/sdj" = { label = "flash", size = 1000 }
          "/dev/sds" = { label = "swap", size = 2 }
        }
        instance = merge(local.database_a.instance, {
          instance_type = "r6i.2xlarge"
        })
        tags = merge(local.database_a.tags, {
          bip-db-name         = "PPBIPINF"
          instance-scheduling = "skip-scheduling"
          oasys-environment   = "preproduction"
          oracle-sids         = "PPBIPINF PPOASYS"
        })
      })

      pp-onr-db-a = merge(local.database_onr_a, {
        config = merge(local.database_onr_a.config, {
          instance_profile_policies = concat(local.database_onr_a.config.instance_profile_policies, [
            "Ec2PreprodDatabasePolicy",
          ])
        })
        instance = merge(local.database_onr_a.instance, {
          instance_type = "r6i.2xlarge"
        })
        ebs_volumes = {
          "/dev/sdb" = { label = "app", size = 100 } # /u01
          "/dev/sdc" = { label = "app", size = 500 } # /u02
          "/dev/sde" = { label = "data", size = 2000 }
          "/dev/sdj" = { label = "flash", size = 600 }
          "/dev/sds" = { label = "swap", size = 2 }
        }
        user_data_cloud_init = merge(module.baseline_presets.ec2_instance.user_data_cloud_init.ssm_agent_ansible_no_tags, {
          args = merge(module.baseline_presets.ec2_instance.user_data_cloud_init.ssm_agent_ansible_no_tags.args, {
            branch = "oracle_11g_oasys_patchset_addition"
          })
        })
        tags = merge(local.database_onr_a.tags, {
          instance-scheduling = "skip-scheduling"
          oasys-environment   = "preproduction"
          oracle-sids         = "PPONRBOD PPOASREP PPONRSYS PPONRAUD"
        })
      })

      pp-oasys-bip-a = merge(local.bip_a, {
        config = merge(local.bip_a.config, {
          instance_profile_policies = concat(local.bip_a.config.instance_profile_policies, [
            "Ec2PreprodBipPolicy",
          ])
        })
        tags = merge(local.bip_a.tags, {
          bip-db-hostname   = "pp-oasys-db-a"
          bip-db-name       = "PPBIPINF"
          oasys-db-hostname = "pp-oasys-db-a"
          oasys-db-name     = "PPOASYS"
          oasys-environment = "preproduction"
        })
      })
    }

    iam_policies = {
      Ec2PreprodBipPolicy = {
        description = "Permissions required for preprod Bip EC2s"
        statements = [
          {
            effect = "Allow"
            actions = [
              "secretsmanager:GetSecretValue",
            ]
            resources = [
              "arn:aws:secretsmanager:*:*:secret:/oracle/database/*PP/bip-*",
              "arn:aws:secretsmanager:*:*:secret:/oracle/database/PP*/bip-*",
              "arn:aws:secretsmanager:*:*:secret:/oracle/bip/preproduction/*",
            ]
          }
        ]
      }
      Ec2PreprodDatabasePolicy = {
        description = "Permissions required for Preprod Database EC2s"
        statements = [
          {
            effect = "Allow"
            actions = [
              "s3:GetBucketLocation",
              "s3:GetObject",
              "s3:GetObjectTagging",
              "s3:ListBucket",
              "s3:PutObject",
              "s3:PutObjectAcl",
              "s3:PutObjectTagging",
              "s3:DeleteObject",
              "s3:RestoreObject",
            ]
            resources = [
              "arn:aws:s3:::prod-oasys-db-backup-bucket*",
              "arn:aws:s3:::prod-oasys-db-backup-bucket*/*",
            ]
          },
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
          },
        ]
      }
      Ec2PreprodWebPolicy = {
        description = "Permissions required for Preprod Web EC2s"
        statements = [
          {
            effect = "Allow"
            actions = [
              "secretsmanager:GetSecretValue",
            ]
            resources = [
              "arn:aws:secretsmanager:*:*:secret:/oracle/database/PPOASYS/apex-passwords*",
              "arn:aws:secretsmanager:*:*:secret:/oracle/database/OASPROD/apex-passwords*",
            ]
          }
        ]
      }
    }

    # options for LBs https://docs.google.com/presentation/d/1RpXpfNY_hw7FjoMw0sdMAdQOF7kZqLUY6qVVtLNavWI/edit?usp=sharing
    lbs = {
      public = {
        access_logs              = true
        enable_delete_protection = false
        idle_timeout             = 3600 # 60 is default
        internal_lb              = false
        force_destroy_bucket     = true
        s3_versioning            = false
        security_groups          = ["public_lb"]
        subnets                  = module.environment.subnets["public"].ids
        tags                     = local.tags

        listeners = {
          https = {
            certificate_names_or_arns = ["pp_oasys_cert"]
            port                      = 443
            protocol                  = "HTTPS"
            ssl_policy                = "ELBSecurityPolicy-TLS13-1-2-2021-06"

            default_action = {
              type = "fixed-response"
              fixed_response = {
                content_type = "text/plain"
                message_body = "Use pp.oasys.service.justice.gov.uk"
                status_code  = "200"
              }
            }

            rules = {
              pp-web-http-8080 = {
                priority = 100
                actions = [{
                  type              = "forward"
                  target_group_name = "pp-oasys-web-a-pb-http-8080"
                }]
                conditions = [
                  {
                    host_header = {
                      values = [
                        "pp.oasys.service.justice.gov.uk",
                        "pp-a.oasys.service.justice.gov.uk",
                        "bridge-pp-oasys.az.justice.gov.uk"
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
        s3_versioning            = false
        security_groups          = ["private_lb"]
        subnets                  = module.environment.subnets["private"].ids
        tags                     = local.tags

        listeners = {
          https = {
            certificate_names_or_arns = ["pp_oasys_cert"]
            port                      = 443
            protocol                  = "HTTPS"
            ssl_policy                = "ELBSecurityPolicy-TLS13-1-2-2021-06"

            default_action = {
              type = "redirect"
              redirect = {
                host        = "pp-int.oasys.service.justice.gov.uk"
                port        = "443"
                protocol    = "HTTPS"
                status_code = "HTTP_302"
              }
            }

            rules = {
              pp-web-http-8080 = {
                priority = 100
                actions = [{
                  type              = "forward"
                  target_group_name = "pp-oasys-web-a-pv-http-8080"
                }]
                conditions = [
                  {
                    host_header = {
                      values = [
                        "pp-int.oasys.service.justice.gov.uk",
                        "pp-a-int.oasys.service.justice.gov.uk",
                        "pp-oasys.az.justice.gov.uk",
                        "oasys-ukwest.pp-oasys.az.justice.gov.uk",
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
      "hmpps-preproduction.modernisation-platform.service.justice.gov.uk" = {
        records = [
          { name = "db.pp.oasys", type = "CNAME", ttl = "3600", records = ["pp-oasys-db-a.oasys.hmpps-preproduction.modernisation-platform.service.justice.gov.uk"] },
          { name = "db.pp.onr", type = "CNAME", ttl = "3600", records = ["pp-onr-db-a.oasys.hmpps-preproduction.modernisation-platform.service.justice.gov.uk"] },
        ]
      }
      "hmpps-preproduction.modernisation-platform.internal" = {
        vpc = { # this makes it a private hosted zone
          id = module.environment.vpc.id
        }
        records = [
          { name = "db.pp.oasys", type = "CNAME", ttl = "3600", records = ["pp-oasys-db-a.oasys.hmpps-preproduction.modernisation-platform.internal"] },
          { name = "db.pp.onr", type = "CNAME", ttl = "3600", records = ["pp-onr-db-a.oasys.hmpps-preproduction.modernisation-platform.internal"] },
        ]
      }
    }

    secretsmanager_secrets = {
      "/oracle/bip/preproduction" = local.secretsmanager_secrets_bip
      "/oracle/database/PPOASYS"  = local.secretsmanager_secrets_oasys_db
      "/oracle/database/PPOASREP" = local.secretsmanager_secrets_db
      "/oracle/database/PPBIPINF" = local.secretsmanager_secrets_bip_db
      "/oracle/database/PPMISTRN" = local.secretsmanager_secrets_db
      "/oracle/database/PPONRSYS" = local.secretsmanager_secrets_db
      "/oracle/database/PPONRAUD" = local.secretsmanager_secrets_db
      "/oracle/database/PPONRBDS" = local.secretsmanager_secrets_db
      "/oracle/database/PPMISTN2" = local.secretsmanager_secrets_db
      "/oracle/database/PPOASRP2" = local.secretsmanager_secrets_db

      # for azure, remove when migrated to aws db
      "/oracle/database/OASPROD" = local.secretsmanager_secrets_oasys_db
    }
  }
}
