# environment specific settings
locals {

  # cloudwatch monitoring config
  production_cloudwatch_monitoring_options = {
    enable_hmpps-oem_monitoring = false
  }

  production_baseline_presets_options = {
    sns_topics = {
      pagerduty_integrations = {
        dso_pagerduty               = "oasys_alarms"
        dba_pagerduty               = "hmpps_shef_dba_low_priority"
        dba_high_priority_pagerduty = "hmpps_shef_dba_high_priority"
      }
    }
  }

  production_config = {

    ec2_common = {
      patch_approval_delay_days = 7
      patch_day                 = "THU"
    }

    baseline_s3_buckets     = {}
    baseline_ssm_parameters = {}

    # baseline_bastion_linux = {
    #   public_key_data = local.public_key_data.keys[local.environment]
    #   tags            = local.tags
    # }

    baseline_secretsmanager_secrets = {
      "/oracle/database/PDOASYS"  = local.secretsmanager_secrets_oasys_db
      "/oracle/database/PTCOASYS" = local.secretsmanager_secrets_oasys_db
      "/oracle/database/TRNOASYS" = local.secretsmanager_secrets_oasys_db

      # "/oracle/database/PDOASREP" = local.secretsmanager_secrets_db
      # "/oracle/database/PDBIPINF" = local.secretsmanager_secrets_bip_db
      # "/oracle/database/PDMISTRN" = local.secretsmanager_secrets_db
      # "/oracle/database/PDONRSYS" = local.secretsmanager_secrets_db
      # "/oracle/database/PDONRAUD" = local.secretsmanager_secrets_db
      # "/oracle/database/PDONRBDS" = local.secretsmanager_secrets_db

      # for azure, remove when migrated to aws db
      # "/oracle/database/OASPROD" = local.secretsmanager_secrets_oasys_db

      # "/oracle/bip/production" = local.secretsmanager_secrets_bip
    }

    baseline_iam_policies = {
      Ec2ProdWebPolicy = {
        description = "Permissions required for Prod Web EC2s"
        statements = [
          {
            effect = "Allow"
            actions = [
              "secretsmanager:GetSecretValue",
            ]
            resources = [
              "arn:aws:secretsmanager:*:*:secret:/oracle/database/PDOASYS/apex-passwords*",
              "arn:aws:secretsmanager:*:*:secret:/oracle/database/OASPROD/apex-passwords*",
            ]
          }
        ]
      }
      Ec2PracticeWebPolicy = {
        description = "Permissions required for practice Web EC2s"
        statements = [
          {
            effect = "Allow"
            actions = [
              "secretsmanager:GetSecretValue",
            ]
            resources = [
              "arn:aws:secretsmanager:*:*:secret:/oracle/database/PTCOASYS/apex-passwords*",
              "arn:aws:secretsmanager:*:*:secret:/oracle/database/OASYSPTC/apex-passwords*",
            ]
          }
        ]
      }
      Ec2TrainingWebPolicy = {
        description = "Permissions required for training Web EC2s"
        statements = [
          {
            effect = "Allow"
            actions = [
              "secretsmanager:GetSecretValue",
            ]
            resources = [
              "arn:aws:secretsmanager:*:*:secret:/oracle/database/TRNOASYS/apex-passwords*",
              "arn:aws:secretsmanager:*:*:secret:/oracle/database/OASYSTRN/apex-passwords*",
            ]
          }
        ]
      }
      Ec2ProdDatabasePolicy = {
        description = "Permissions required for Prod Database EC2s"
        statements = [
          {
            effect = "Allow"
            actions = [
              "s3:GetBucketLocation",
              "s3:GetObject",
              "s3:GetObjectTagging",
              "s3:ListBucket",
            ]
            resources = [
              "arn:aws:s3:::prod-${local.application_name}-db-backup-bucket*",
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
              "arn:aws:secretsmanager:*:*:secret:/oracle/database/*PD/*",
              "arn:aws:secretsmanager:*:*:secret:/oracle/database/PD*/*",
            ]
          },
        ]
      }
      Ec2PtcTrnDatabasePolicy = {
        description = "Permissions required for practice and training Database EC2s"
        statements = [
          {
            effect = "Allow"
            actions = [
              "s3:GetBucketLocation",
              "s3:GetObject",
              "s3:GetObjectTagging",
              "s3:ListBucket",
            ]
            resources = [
              "arn:aws:s3:::prod-${local.application_name}-db-backup-bucket*",
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
              "arn:aws:secretsmanager:*:*:secret:/oracle/database/*PTC/*",
              "arn:aws:secretsmanager:*:*:secret:/oracle/database/PTC*/*",
              "arn:aws:secretsmanager:*:*:secret:/oracle/database/*TRN/*",
              "arn:aws:secretsmanager:*:*:secret:/oracle/database/TRN*/*",
            ]
          },
        ]
      }
      Ec2ProdBipPolicy = {
        description = "Permissions required for preprod Bip EC2s"
        statements = [
          {
            effect = "Allow"
            actions = [
              "secretsmanager:GetSecretValue",
            ]
            resources = [
              "arn:aws:secretsmanager:*:*:secret:/oracle/database/*PD/bip-*",
              "arn:aws:secretsmanager:*:*:secret:/oracle/database/PD*/bip-*",
              "arn:aws:secretsmanager:*:*:secret:/oracle/bip/production/*",
            ]
          }
        ]
      }
    }

    baseline_ec2_instances = {
      "ptctrn-${local.application_name}-db-a" = merge(local.database_a, {
        config = merge(local.database_a.config, {
          instance_profile_policies = concat(local.database_a.config.instance_profile_policies, [
            "Ec2PtcTrnDatabasePolicy",
          ])
        })
        instance = merge(local.database_a.instance, {
          instance_type = "r6i.2xlarge"
        })
        tags = merge(local.database_a.tags, {
          #bip-db-name         = "PPBIPINF"
          oracle-sids         = "PTCOASYS TRNOASYS"
        })
      })
    }

    baseline_ec2_autoscaling_groups = {
      # "pd-${local.application_name}-web-trn-a" = merge(local.webserver_a, {
      #   config = merge(module.baseline_presets.ec2_instance.config.default, {
      #     ami_name                  = "${local.application_name}_webserver_release_*"
      #     ssm_parameters_prefix     = "ec2-web-trn/"
      #     iam_resource_names_prefix = "ec2-web-trn"
      #   })
      #   tags = merge(local.webserver_a.tags, {
      #     description                             = "${local.environment} training ${local.application_name} web"
      #     "${local.application_name}-environment" = "trn"
      #     oracle-db-sid                           = "OASTRN"
      #   })
      # })
    }

    # If your DNS records are in Fix 'n' Go, setup will be a 2 step process, see the acm_certificate module readme
    # if making changes, comment out the listeners that use the cert, edit the cert, recreate the listeners
    baseline_acm_certificates = {
      "pd_${local.application_name}_cert" = {
        # domain_name limited to 64 chars so use modernisation platform domain for this
        # and put the wildcard in the san
        domain_name = "oasys.service.justice.gov.uk"
        subject_alternate_names = [
          "*.oasys.service.justice.gov.uk",
          "bridge-oasys.az.justice.gov.uk",
          "oasys.az.justice.gov.uk",
          "p-oasys.az.justice.gov.uk",
          "*.oasys.az.justice.gov.uk",
          "*.bridge-oasys.az.justice.gov.uk",
          "*.p-oasys.az.justice.gov.uk",
        ]
        external_validation_records_created = true
        cloudwatch_metric_alarms            = module.baseline_presets.cloudwatch_metric_alarms.acm
        tags = {
          description = "cert for ${local.application_name} ${local.environment} domains"
        }
      }
    }

    baseline_lbs = {
      private = {
        enable_delete_protection = false # change to true before we actually use
        force_destroy_bucket     = false
        idle_timeout             = "3600"
        internal_lb              = true
        security_groups          = ["private_lb"]
        subnets                  = module.environment.subnets["private"].ids
        existing_target_groups   = {}
        tags                     = local.tags
        listeners = {
          https = {
            port                      = 443
            protocol                  = "HTTPS"
            ssl_policy                = "ELBSecurityPolicy-2016-08"
            certificate_names_or_arns = ["application_environment_wildcard_cert"]
            default_action = {
              type = "fixed-response"
              fixed_response = {
                content_type = "text/plain"
                message_body = "Not implemented"
                status_code  = "501"
              }
            }
            rules = {
            }
          }
        }
      }
    }

    baseline_route53_zones = {
      # (module.environment.domains.public.short_name) = { # "oasys.service.justice.gov.uk"
      #   records = [
      #     { name = "db", type = "A", ttl = "3600", records = ["10.40.6.133"] },     #     "db.oasys.service.justice.gov.uk" currently pointing to azure db PDODL00011
      #     { name = "trn.db", type = "A", ttl = "3600", records = ["10.40.6.138"] }, # "trn.db.oasys.service.justice.gov.uk" currently pointing to azure db PDODL00019
      #     { name = "ptc.db", type = "A", ttl = "3600", records = ["10.40.6.138"] }, # "ptc.db.oasys.service.justice.gov.uk" currently pointing to azure db PDODL00019
      #   ]
      #   lb_alias_records = [
      #     { name = "web", type = "A", lbs_map_key = "private" },     #     web.oasys.service.justice.gov.uk
      #     { name = "trn.web", type = "A", lbs_map_key = "private" }, # trn.web.oasys.service.justice.gov.uk
      #     { name = "ptc.web", type = "A", lbs_map_key = "private" }, # ptc.web.oasys.service.justice.gov.uk
      #   ]
      # }
    }

    baseline_cloudwatch_log_groups = {
      session-manager-logs = {
        retention_in_days = 400
      }
      cwagent-var-log-messages = {
        retention_in_days = 90
      }
      cwagent-var-log-secure = {
        retention_in_days = 400
      }
      cwagent-windows-system = {
        retention_in_days = 90
      }
      cwagent-oasys-autologoff = {
        retention_in_days = 400
      }
      cwagent-web-logs = {
        retention_in_days = 90
      }
    }
  }
}
