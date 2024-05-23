# environment specific settings
locals {

  # cloudwatch monitoring config
  preproduction_cloudwatch_monitoring_options = {}

  preproduction_baseline_presets_options = {
    sns_topics = {
      pagerduty_integrations = {
        dso_pagerduty               = "oasys_alarms"
        dba_pagerduty               = "hmpps_shef_dba_low_priority"
        dba_high_priority_pagerduty = "hmpps_shef_dba_low_priority"
      }
    }
  }

  preproduction_config = {

    ec2_common = {
      patch_approval_delay_days = 3
      patch_day                 = "TUE"
    }

    baseline_s3_buckets     = {}
    baseline_ssm_parameters = {}

    baseline_secretsmanager_secrets = {
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

      "/oracle/bip/preproduction" = local.secretsmanager_secrets_bip
    }

    baseline_iam_policies = {
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
    }

    baseline_ec2_instances = {
      "pp-oasys-db-a" = merge(local.database_a, {
        config = merge(local.database_a.config, {
          instance_profile_policies = concat(local.database_a.config.instance_profile_policies, [
            "Ec2PreprodDatabasePolicy",
          ])
        })
        instance = merge(local.database_a.instance, {
          instance_type = "r6i.2xlarge"
        })
        tags = merge(local.database_a.tags, {
          bip-db-name         = "PPBIPINF"
          instance-scheduling = "skip-scheduling"
          oracle-sids         = "PPBIPINF PPOASYS"
        })
      })

      "pp-onr-db-a" = merge(local.database_onr_a, {
        config = merge(local.database_onr_a.config, {
          instance_profile_policies = concat(local.database_onr_a.config.instance_profile_policies, [
            "Ec2PreprodDatabasePolicy",
          ])
        })
        instance = merge(local.database_onr_a.instance, {
          instance_type = "r6i.2xlarge"
        })
        user_data_cloud_init = merge(module.baseline_presets.ec2_instance.user_data_cloud_init.ssm_agent_ansible_no_tags, {
          args = merge(module.baseline_presets.ec2_instance.user_data_cloud_init.ssm_agent_ansible_no_tags.args, {
            branch = "oracle_11g_oasys_patchset_addition"
          })
        })
        tags = merge(local.database_onr_a.tags, {
          instance-scheduling = "skip-scheduling"
          oracle-sids         = "PPONRBOD PPOASREP PPONRSYS PPONRAUD"
        })
      })

      "pp-oasys-bip-a" = merge(local.bip_a, {
        config = merge(local.bip_a.config, {
          instance_profile_policies = concat(local.bip_a.config.instance_profile_policies, [
            "Ec2PreprodBipPolicy",
          ])
        })
        tags = merge(local.bip_a.tags, {
          bip-db-name       = "PPBIPINF"
          bip-db-hostname   = "pp-oasys-db-a"
          oasys-db-name     = "PPOASYS"
          oasys-db-hostname = "pp-oasys-db-a"
        })
      })
    }


    baseline_ec2_autoscaling_groups = {
      "pp-oasys-web-a" = merge(local.webserver, {
        config = merge(local.webserver.config, {
          ami_name                  = "oasys_webserver_release_*"
          ssm_parameters_prefix     = "ec2-web-pp/"
          iam_resource_names_prefix = "ec2-web-pp"
          instance_profile_policies = concat(local.webserver.config.instance_profile_policies, [
            "Ec2PreprodWebPolicy",
          ])
        })
        autoscaling_schedules = {
          "scale_up" = {
            recurrence = "0 5 * * Mon-Fri"
          }
          "scale_down" = {
            desired_capacity = 0
            recurrence       = "0 19 * * Mon-Fri"
          }
        }
        tags = merge(local.webserver.tags, {
          oracle-db-hostname = "db.pp.oasys.hmpps-preproduction.modernisation-platform.internal"
          oracle-db-sid      = "PPOASYS" # "OASPROD"
        })
      })
    }

    # If your DNS records are in Fix 'n' Go, setup will be a 2 step process, see the acm_certificate module readme
    # if making changes, comment out the listeners that use the cert, edit the cert, recreate the listeners
    baseline_acm_certificates = {
      "pp_oasys_cert" = {
        # domain_name limited to 64 chars so use modernisation platform domain for this
        # and put the wildcard in the san
        domain_name = "pp.oasys.service.justice.gov.uk"
        subject_alternate_names = [
          "pp-int.oasys.service.justice.gov.uk",
          "bridge-pp-oasys.az.justice.gov.uk",
          "pp-oasys.az.justice.gov.uk",
          "*.pp-oasys.az.justice.gov.uk",
        ]
        external_validation_records_created = true
        cloudwatch_metric_alarms            = module.baseline_presets.cloudwatch_metric_alarms.acm
        tags = {
          description = "cert for oasys ${local.environment} domains"
        }
      }
    }

    # options for LBs https://docs.google.com/presentation/d/1RpXpfNY_hw7FjoMw0sdMAdQOF7kZqLUY6qVVtLNavWI/edit?usp=sharing
    baseline_lbs = {
      public = {
        internal_lb              = false
        access_logs              = true
        s3_versioning            = false
        force_destroy_bucket     = true
        enable_delete_protection = false
        existing_target_groups = {
        }
        idle_timeout    = 3600 # 60 is default
        security_groups = ["public_lb"]
        subnets         = module.environment.subnets["public"].ids
        tags            = local.tags

        listeners = {
          https = {
            port                      = 443
            protocol                  = "HTTPS"
            ssl_policy                = "ELBSecurityPolicy-TLS13-1-2-2021-06"
            certificate_names_or_arns = ["pp_oasys_cert"]
            default_action = {
              type = "fixed-response"
              fixed_response = {
                content_type = "text/plain"
                message_body = "Use pp.oasys.service.justice.gov.uk"
                status_code  = "200"
              }
            }
            # default_action = {
            #   type              = "forward"
            #   target_group_name = "pp-oasys-web-a-pb-http-8080"
            # }
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
        internal_lb              = true
        access_logs              = true
        s3_versioning            = false
        force_destroy_bucket     = true
        enable_delete_protection = false
        existing_target_groups   = {}
        idle_timeout             = 3600 # 60 is default
        security_groups          = ["private_lb"]
        subnets                  = module.environment.subnets["private"].ids
        tags                     = local.tags
        listeners = {
          https = {
            port                      = 443
            protocol                  = "HTTPS"
            ssl_policy                = "ELBSecurityPolicy-TLS13-1-2-2021-06"
            certificate_names_or_arns = ["pp_oasys_cert"]
            default_action = {
              type = "redirect"
              redirect = {
                host        = "pp-int.oasys.service.justice.gov.uk"
                port        = "443"
                protocol    = "HTTPS"
                status_code = "HTTP_302"
              }
            }
            # default_action = {
            #   type = "fixed-response"
            #   fixed_response = {
            #     content_type = "text/plain"
            #     message_body = "use pp-int.oasys.service.justice.gov.uk"
            #     status_code  = "200"
            #   }
            # }
            # default_action = {
            #   type              = "forward"
            #   target_group_name = "pp-oasys-web-a-pv-http-8080"
            # }
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

    baseline_route53_zones = {
      #
      # public
      #
      "hmpps-preproduction.modernisation-platform.service.justice.gov.uk" = { 
        records = [
          { name = "db.pp.oasys", type = "CNAME", ttl = "3600", records = ["pp-oasys-db-a.oasys.hmpps-preproduction.modernisation-platform.service.justice.gov.uk"] },
          { name = "db.pp.onr", type = "CNAME", ttl = "3600", records = ["pp-onr-db-a.oasys.hmpps-preproduction.modernisation-platform.service.justice.gov.uk"] },
        ]
      }
      #
      # internal/private
      #
      "hmpps-preproduction.modernisation-platform.internal" = {
        vpc = {  # this makes it a private hosted zone
          id = module.environment.vpc.id
        }
        records = [
          { name = "db.pp.oasys", type = "CNAME", ttl = "3600", records = ["pp-oasys-db-a.oasys.hmpps-preproduction.modernisation-platform.internal"] },
          { name = "db.pp.onr", type = "CNAME", ttl = "3600", records = ["pp-onr-db-a.oasys.hmpps-preproduction.modernisation-platform.internal"] },
        ]
        lb_alias_records = [
        ]
      }
    }

    baseline_cloudwatch_log_groups = {
      session-manager-logs = {
        retention_in_days = 14
      }
      cwagent-var-log-messages = {
        retention_in_days = 14
      }
      cwagent-var-log-secure = {
        retention_in_days = 14
      }
      cwagent-windows-system = {
        retention_in_days = 14
      }
      cwagent-oasys-autologoff = {
        retention_in_days = 14
      }
      cwagent-web-logs = {
        retention_in_days = 14
      }
    }


  }
}
