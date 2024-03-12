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
      "/oracle/database/PDOASYS" = local.secretsmanager_secrets_oasys_db
      "/oracle/database/PROASYS" = local.secretsmanager_secrets_oasys_db
      "/oracle/database/TROASYS" = local.secretsmanager_secrets_oasys_db

      # "/oracle/database/PDOASREP" = local.secretsmanager_secrets_db
      # "/oracle/database/PDBIPINF" = local.secretsmanager_secrets_bip_db
      # "/oracle/database/PDMISTRN" = local.secretsmanager_secrets_db
      # "/oracle/database/PDONRSYS" = local.secretsmanager_secrets_db
      # "/oracle/database/PDONRAUD" = local.secretsmanager_secrets_db
      # "/oracle/database/PDONRBDS" = local.secretsmanager_secrets_db

      "/oracle/database/TRBIPINF" = local.secretsmanager_secrets_bip_db

      # for azure, remove when migrated to aws db
      # "/oracle/database/OASPROD" = local.secretsmanager_secrets_oasys_db

      "/oracle/bip/production" = local.secretsmanager_secrets_bip
      "/oracle/bip/trn"        = local.secretsmanager_secrets_bip
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
      Ec2PtcWebPolicy = {
        description = "Permissions required for practice Web EC2s"
        statements = [
          {
            effect = "Allow"
            actions = [
              "secretsmanager:GetSecretValue",
            ]
            resources = [
              "arn:aws:secretsmanager:*:*:secret:/oracle/database/PROASYS/apex-passwords*",
              "arn:aws:secretsmanager:*:*:secret:/oracle/database/OASYSPTC/apex-passwords*",
            ]
          }
        ]
      }
      Ec2TrnWebPolicy = {
        description = "Permissions required for training Web EC2s"
        statements = [
          {
            effect = "Allow"
            actions = [
              "secretsmanager:GetSecretValue",
            ]
            resources = [
              "arn:aws:secretsmanager:*:*:secret:/oracle/database/TROASYS/apex-passwords*",
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
              "arn:aws:secretsmanager:*:*:secret:/oracle/database/*PR/*",
              "arn:aws:secretsmanager:*:*:secret:/oracle/database/PR*/*",
              "arn:aws:secretsmanager:*:*:secret:/oracle/database/*TR/*",
              "arn:aws:secretsmanager:*:*:secret:/oracle/database/TR*/*",
            ]
          },
        ]
      }
      Ec2TrnBipPolicy = {
        description = "Permissions required for training Bip EC2s"
        statements = [
          {
            effect = "Allow"
            actions = [
              "secretsmanager:GetSecretValue",
            ]
            resources = [
              "arn:aws:secretsmanager:*:*:secret:/oracle/database/*TR/bip-*",
              "arn:aws:secretsmanager:*:*:secret:/oracle/database/TR*/bip-*",
              "arn:aws:secretsmanager:*:*:secret:/oracle/bip/trn/*",
            ]
          }
        ]
      }
      Ec2ProdBipPolicy = {
        description = "Permissions required for prod Bip EC2s"
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
      #"pd-${local.application_name}-db-a" = merge(local.database_a, {
      #   config = merge(local.database_a.config, {
      #     instance_profile_policies = concat(local.database_a.config.instance_profile_policies, [
      #       "Ec2ProdDatabasePolicy",
      #     ])
      #   })
      #   tags = merge(local.database_a.tags, {
      #     bip-db-name                             = "PDBIPINF"
      #     oracle-sids                             = "PDBIPINF PDOASYS"
      #   })
      # })

      "ptctrn-${local.application_name}-db-a" = merge(local.database_a, {
        config = merge(local.database_a.config, {
          instance_profile_policies = concat(local.database_a.config.instance_profile_policies, [
            "Ec2PtcTrnDatabasePolicy",
          ])
        })
        instance = merge(local.database_a.instance, {
          instance_type = "r6i.xlarge"
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
            size  = 300
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
            size  = 2
          }
        }
        ebs_volume_config = {
          data = {
            iops       = 500
            type       = "gp3"
            throughput = 125
            total_size = 200
          }
          flash = {
            iops       = 500
            type       = "gp3"
            throughput = 125
            total_size = 50
          }
        }
        tags = merge(local.database_a.tags, {
          description                             = "practice and training ${local.application_name} database"
          "${local.application_name}-environment" = "ptctrn"
          bip-db-name                             = "TRBIPINF"
          oracle-sids = "PROASYS TROASYS TRBIPINF"
        })
      })

      "trn-${local.application_name}-bip-a" = merge(local.bip_a, {
        config = merge(local.bip_a.config, {
          instance_profile_policies = concat(local.bip_a.config.instance_profile_policies, [
            "Ec2TrnBipPolicy",
          ])
        })
        tags = merge(local.bip_a.tags, {
          bip-db-name       = "TRBIPINF"
          bip-db-hostname   = "ptctrn-oasys-db-a"
          oasys-db-name     = "TROASYS"
          oasys-db-hostname = "ptctrn-oasys-db-a"
        })
      })
    }

    baseline_ec2_autoscaling_groups = {
      # "pd-${local.application_name}-web-a" = merge(local.webserver_a, {
      #   tags = merge(local.webserver_a.tags, {
      #     oracle-db-sid                           = "PDOASYS"
      #   })
      # })

      "ptc-${local.application_name}-web-a" = merge(local.webserver_a, {
        config = merge(local.webserver_a.config, {
          ssm_parameters_prefix     = "ec2-web-ptc/"
          iam_resource_names_prefix = "ec2-web-ptc"
          instance_profile_policies = concat(local.webserver_a.config.instance_profile_policies, [
            "Ec2PtcWebPolicy",
          ])
        })
        tags = merge(local.webserver_a.tags, {
          description                             = "${local.environment} practice ${local.application_name} web"
          "${local.application_name}-environment" = "ptc"
          oracle-db-sid                           = "PROASYS"
          oracle-db-hostname                      = "db.ptc.oasys.hmpps-production.modernisation-platform.internal"
        })
      })

      "trn-${local.application_name}-web-a" = merge(local.webserver_a, {
        config = merge(local.webserver_a.config, {
          ssm_parameters_prefix     = "ec2-web-trn/"
          iam_resource_names_prefix = "ec2-web-trn"
          instance_profile_policies = concat(local.webserver_a.config.instance_profile_policies, [
            "Ec2TrnWebPolicy",
          ])
        })
        tags = merge(local.webserver_a.tags, {
          description                             = "${local.environment} training ${local.application_name} web"
          "${local.application_name}-environment" = "trn"
          oracle-db-sid                           = "TROASYS"
          oracle-db-hostname                      = "db.trn.oasys.hmpps-production.modernisation-platform.internal"
        })
      })
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
      # public = {
      #   internal_lb              = false
      #   access_logs              = false
      #   s3_versioning            = false
      #   force_destroy_bucket     = true
      #   enable_delete_protection = false
      #   existing_target_groups   = {}
      #   idle_timeout             = 3600 # 60 is default
      #   security_groups          = ["public_lb"]
      #   subnets                  = module.environment.subnets["public"].ids
      #   tags                     = local.tags

      #   listeners = {
      #     https = {
      #       port                      = 443
      #       protocol                  = "HTTPS"
      #       ssl_policy                = "ELBSecurityPolicy-2016-08"
      #       certificate_names_or_arns = ["pd_${local.application_name}_cert"]
      #       default_action = {
      #         type = "fixed-response"
      #         fixed_response = {
      #           content_type = "text/plain"
      #           message_body = "Use www.oasys.service.justice.gov.uk, or for practice ptc.oasys.service.justice.gov.uk, or for training trn.oasys.service.justice.gov.uk"
      #           status_code  = "200"
      #         }
      #       }
      #       # default_action = {
      #       #   type              = "forward"
      #       #   target_group_name = "pd-${local.application_name}-web-a-pb-http-8080"
      #       # }
      #       rules = {
      #         pd-web-http-8080 = {
      #           priority = 100
      #           actions = [{
      #             type              = "forward"
      #             target_group_name = "pd-${local.application_name}-web-a-pb-http-8080"
      #           }]
      #           conditions = [
      #             {
      #               host_header = {
      #                 values = [
      #                   "oasys.service.justice.gov.uk",
      #                   "bridge-oasys.az.justice.gov.uk",
      #                   "www.oasys.service.justice.gov.uk",
      #                 ]
      #               }
      #             }
      #           ]
      #         }
      #         pd-web-a-http-8080 = {
      #           priority = 200
      #           actions = [{
      #             type              = "forward"
      #             target_group_name = "pd-${local.application_name}-web-a-pb-http-8080"
      #           }]
      #           conditions = [
      #             {
      #               host_header = {
      #                 values = [
      #                   "a.oasys.service.justice.gov.uk",
      #                 ]
      #               }
      #             }
      #           ]
      #         }
      #         pd-web-b-http-8080 = {
      #           priority = 200
      #           actions = [{
      #             type              = "forward"
      #             target_group_name = "pd-${local.application_name}-web-b-pb-http-8080"
      #           }]
      #           conditions = [
      #             {
      #               host_header = {
      #                 values = [
      #                   "b.oasys.service.justice.gov.uk",
      #                 ]
      #               }
      #             }
      #           ]
      #         }
      #       }
      #     }
      #   }
      # }
      private = {
        internal_lb              = true
        access_logs              = true
        s3_versioning            = false
        force_destroy_bucket     = false
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
            ssl_policy                = "ELBSecurityPolicy-2016-08"
            certificate_names_or_arns = ["pd_${local.application_name}_cert"]
            default_action = {
              type = "fixed-response"
              fixed_response = {
                content_type = "text/plain"
                message_body = "use int.oasys.service.justice.gov.uk, or for practice ptc-int.oasys.service.justice.gov.uk, or for training trn-int.oasys.service.justice.gov.uk"
                status_code  = "200"
              }
            }
            # default_action = {
            #   type              = "forward"
            #   target_group_name = "pd-${local.application_name}-web-a-pv-http-8080"
            # }
            rules = {
              # pd-web-http-8080 = {
              #   priority = 100
              #   actions = [{
              #     type              = "forward"
              #     target_group_name = "pd-${local.application_name}-web-a-pv-http-8080"
              #   }]
              #   conditions = [
              #     {
              #       host_header = {
              #         values = [
              #           "int.oasys.service.justice.gov.uk",
              #           "oasys-ukwest.oasys.az.justice.gov.uk",
              #           "oasys.az.justice.gov.uk",
              #           "p-oasys.az.justice.gov.uk",
              #         ]
              #       }
              #     }
              #   ]
              # }
              # pd-web-a-http-8080 = {
              #   priority = 200
              #   actions = [{
              #     type              = "forward"
              #     target_group_name = "pd-${local.application_name}-web-a-pv-http-8080"
              #   }]
              #   conditions = [
              #     {
              #       host_header = {
              #         values = [
              #           "a-int.oasys.service.justice.gov.uk",
              #         ]
              #       }
              #     }
              #   ]
              # }
              # pd-web-b-http-8080 = {
              #   priority = 200
              #   actions = [{
              #     type              = "forward"
              #     target_group_name = "pd-${local.application_name}-web-b-pv-http-8080"
              #   }]
              #   conditions = [
              #     {
              #       host_header = {
              #         values = [
              #           "b-int.oasys.service.justice.gov.uk",
              #         ]
              #       }
              #     }
              #   ]
              # }
            }
          }
        }
      }
    }

    baseline_route53_zones = {
      #
      # public
      #
      (module.environment.domains.public.business_unit_environment) = { # hmpps-production.modernisation-platform.service.justice.gov.uk
        records = [
          # { name = "db.${local.application_name}",     type = "CNAME", ttl = "3600", records = ["pd-oasys-db-a.oasys.hmpps-production.modernisation-platform.service.justice.gov.uk"] },
          { name = "db.trn.${local.application_name}", type = "CNAME", ttl = "3600", records = ["ptctrn-oasys-db-a.oasys.hmpps-production.modernisation-platform.service.justice.gov.uk"] },
          { name = "db.ptc.${local.application_name}", type = "CNAME", ttl = "3600", records = ["ptctrn-oasys-db-a.oasys.hmpps-production.modernisation-platform.service.justice.gov.uk"] },
          # { name = "db.${local.application_name}",     type = "A",     ttl = "3600", records = ["10.40.6.133"] },     #     "db.oasys.service.justice.gov.uk" currently pointing to azure db PDODL00011
          # { name = "db.trn${local.application_name}", type = "A",     ttl = "3600", records = ["10.40.6.138"] }, # "trn.db.oasys.service.justice.gov.uk" currently pointing to azure db PDODL00019
          # { name = "db.ptc.${local.application_name}", type = "A",     ttl = "3600", records = ["10.40.6.138"] }, # "ptc.db.oasys.service.justice.gov.uk" currently pointing to azure db PDODL00019
        ]
      }
      #
      # internal/private
      #
      (module.environment.domains.internal.business_unit_environment) = { # hmpps-production.modernisation-platform.internal
        vpc = {                                                           # this makes it a private hosted zone
          id = module.environment.vpc.id
        }
        records = [
          # { name = "db.${local.application_name}",     type = "CNAME", ttl = "3600", records = ["pd-oasys-db-a.oasys.hmpps-production.modernisation-platform.internal"] }, # for aws
          { name = "db.trn.${local.application_name}", type = "CNAME", ttl = "3600", records = ["ptctrn-oasys-db-a.oasys.hmpps-production.modernisation-platform.service.justice.gov.uk"] },
          { name = "db.ptc.${local.application_name}", type = "CNAME", ttl = "3600", records = ["ptctrn-oasys-db-a.oasys.hmpps-production.modernisation-platform.service.justice.gov.uk"] },
          # { name = "db.${local.application_name}",     type = "A",     ttl = "3600", records = ["10.40.40.133"] }, #        "db.oasys.service.justice.gov.uk" currently pointing to azure db PDODL00011
          # { name = "db.trn.${local.application_name}", type = "A",     ttl = "3600", records = ["10.40.6.138"] }, # "trn.db.oasys.service.justice.gov.uk" currently pointing to azure db PDODL00019
          # { name = "db.ptc.${local.application_name}", type = "A",     ttl = "3600", records = ["10.40.6.138"] }, # "ptc.db.oasys.service.justice.gov.uk" currently pointing to azure db PDODL00019
        ]
      }
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
