# environment specific settings
locals {
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
      "/oracle/database/PPAZBIPI" = local.secretsmanager_secrets_bip_db
      "/oracle/database/PPBIPINF" = local.secretsmanager_secrets_bip_db
      "/oracle/database/PPMISTRN" = local.secretsmanager_secrets_db
      "/oracle/database/PPONRSYS" = local.secretsmanager_secrets_db
      "/oracle/database/PPONRAUD" = local.secretsmanager_secrets_db
      "/oracle/database/PPONRBDS" = local.secretsmanager_secrets_db
      "/oracle/bip/preprod"       = local.secretsmanager_secrets_bip

      # for azure, remove when migrated to aws db
      "/oracle/database/OASPROD"  = local.secretsmanager_secrets_oasys_db
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
            ]
            resources = [
              "arn:aws:s3:::prod-{local.application_name}-db-backup-bucket*",
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
              "arn:aws:secretsmanager:*:*:secret:/oracle/bip/preprod/*",
              "arn:aws:secretsmanager:*:*:secret:/oracle/database/*PP/bip-*",
              "arn:aws:secretsmanager:*:*:secret:/oracle/database/PP*/bip-*",
            ]
          }
        ]
      }
    }

    baseline_ec2_instances = {
    }

    baseline_ec2_autoscaling_groups = {
      "pp-${local.application_name}-db-a" = merge(local.database_a, {
        config = merge(local.database_a.config, {
          instance_profile_policies = concat(local.database_a.config.instance_profile_policies, [
            "Ec2PreprodDatabasePolicy",
          ])
        })
        user_data_cloud_init = merge(module.baseline_presets.ec2_instance.user_data_cloud_init.ssm_agent_ansible_no_tags, {
          args = merge(module.baseline_presets.ec2_instance.user_data_cloud_init.ssm_agent_ansible_no_tags.args, {
            branch = "main"
          })
        })
        tags = merge(local.database_a.tags, {
          instance-scheduling = "skip-scheduling"
        })
      })

      "pp-${local.application_name}-web-a" = merge(local.webserver_a, {
        config = merge(module.baseline_presets.ec2_instance.config.default, {
          ami_name                  = "oasys_webserver_release_*"
          ssm_parameters_prefix     = "ec2-web-pp/"
          iam_resource_names_prefix = "ec2-web-pp"
          instance_profile_policies = concat(local.webserver_a.config.instance_profile_policies, [
            "Ec2PreprodWebPolicy",
          ])
        })
        tags = merge(local.webserver_a.tags, {
          oracle-db-hostname = "PPODL00009.azure.noms.root" # "db.pp.oasys.hmpps-preproduction.modernisation-platform.internal"
          oracle-db-sid      = "OASPROD" # "PPOASYS"
        })
      })
    }

    # If your DNS records are in Fix 'n' Go, setup will be a 2 step process, see the acm_certificate module readme
    # if making changes, comment out the listeners that use the cert, edit the cert, recreate the listeners
    baseline_acm_certificates = {
      "pp_${local.application_name}_cert" = {
        # domain_name limited to 64 chars so use modernisation platform domain for this
        # and put the wildcard in the san
        domain_name = "pp.oasys.service.justice.gov.uk"
        subject_alternate_names = [
          "pp-int.oasys.service.justice.gov.uk",
          "pp-a.oasys.service.justice.gov.uk",
          "pp-a-int.oasys.service.justice.gov.uk",
          "pp-b.oasys.service.justice.gov.uk",
          "pp-b-int.oasys.service.justice.gov.uk",
          "bridge-pp-oasys.az.justice.gov.uk",
          "pp-oasys.az.justice.gov.uk",
          "*.pp-oasys.az.justice.gov.uk",
        ]
        external_validation_records_created = false
        cloudwatch_metric_alarms            = module.baseline_presets.cloudwatch_metric_alarms.acm
        tags = {
          description = "cert for ${local.application_name} ${local.environment} domains"
        }
      }
    }

    baseline_lbs = {
      public = {
        internal_lb              = false
        access_logs              = false
        s3_versioning            = false
        force_destroy_bucket     = true
        enable_delete_protection = false
        existing_target_groups = {
        }
        idle_timeout    = 60 # 60 is default
        security_groups = ["public_lb"]
        subnets         = module.environment.subnets["public"].ids
        tags            = local.tags

        listeners = {
          # https = {
          #   port                      = 443
          #   protocol                  = "HTTPS"
          #   ssl_policy                = "ELBSecurityPolicy-2016-08"
          #   certificate_names_or_arns = ["pp_${local.application_name}_cert"]
          #   default_action = {
          #     type = "fixed-response"
          #     fixed_response = {
          #       content_type = "text/plain"
          #       message_body = "Use pp.oasys.service.justice.gov.uk"
          #       status_code  = "200"
          #     }
          #   }
          #   # default_action = {
          #   #   type              = "forward"
          #   #   target_group_name = "pp-${local.application_name}-web-a-pb-http-8080"
          #   # }
          #   rules = {
          #     pp-web-http-8080 = {
          #       priority = 100
          #       actions = [{
          #         type              = "forward"
          #         target_group_name = "pp-${local.application_name}-web-a-pb-http-8080"
          #       }]
          #       conditions = [
          #         {
          #           host_header = {
          #             values = [
          #               "pp.oasys.service.justice.gov.uk",
          #               "pp-a.oasys.service.justice.gov.uk",
          #               "bridge-pp-oasys.az.justice.gov.uk"
          #             ]
          #           }
          #         }
          #       ]
          #     }
          #     # pp-web-b-http-8080 = {
          #     #   priority = 200
          #     #   actions = [{
          #     #     type              = "forward"
          #     #     target_group_name = "pp-${local.application_name}-web-b-pb-http-8080"
          #     #   }]
          #     #   conditions = [
          #     #     {
          #     #       host_header = {
          #     #         values = [
          #     #           "pp-b.oasys.service.justice.gov.uk",
          #     #         ]
          #     #       }
          #     #     }
          #     #   ]
          #     # }
          #   }
          # }
        }
      }
      private = {
        internal_lb = true
        access_logs = true
        s3_versioning            = false
        force_destroy_bucket     = true
        enable_delete_protection = false
        existing_target_groups   = {}
        idle_timeout             = 60 # 60 is default
        security_groups          = ["private_lb"]
        subnets                  = module.environment.subnets["private"].ids
        tags                     = local.tags
        listeners = {
          # https = {
          #   port                      = 443
          #   protocol                  = "HTTPS"
          #   ssl_policy                = "ELBSecurityPolicy-2016-08"
          #   certificate_names_or_arns = ["pp_${local.application_name}_cert"]
          #   default_action = {
          #     type = "fixed-response"
          #     fixed_response = {
          #       content_type = "text/plain"
          #       message_body = "use pp-int.oasys.service.justice.gov.uk"
          #       status_code  = "200"
          #     }
          #   }
          #   # default_action = {
          #   #   type              = "forward"
          #   #   target_group_name = "pp-${local.application_name}-web-a-pv-http-8080"
          #   # }
          #   rules = {
          #     pp-web-http-8080 = {
          #       priority = 100
          #       actions = [{
          #         type              = "forward"
          #         target_group_name = "pp-${local.application_name}-web-a-pv-http-8080"
          #       }]
          #       conditions = [
          #         {
          #           host_header = {
          #             values = [
          #               "pp-int.oasys.service.justice.gov.uk",
          #               "pp-a-int.oasys.service.justice.gov.uk",
          #               "pp-oasys.az.justice.gov.uk",
          #               "oasys-ukwest.pp-oasys.az.justice.gov.uk",
          #             ]
          #           }
          #         }
          #       ]
          #     }
          #     # pp-web-b-http-8080 = {
          #     #   priority = 200
          #     #   actions = [{
          #     #     type              = "forward"
          #     #     target_group_name = "pp-${local.application_name}-web-b-pv-http-8080"
          #     #   }]
          #     #   conditions = [
          #     #     {
          #     #       host_header = {
          #     #         values = [
          #     #           "pp-b-int.oasys.service.justice.gov.uk",
          #     #         ]
          #     #       }
          #     #     }
          #     #   ]
          #     # }
          #   }
          # }
        }
      }
    }

    baseline_route53_zones = {
      #
      # public
      #
      # "${local.application_name}.service.justice.gov.uk" = {
      #   lb_alias_records = [
      # { name = "pp",    type = "A", lbs_map_key = "public" }, #    pp.oasys.service.justice.gov.uk 
      # { name = "db.pp", type = "A", lbs_map_key = "public" }, # db.pp.oasys.service.justice.gov.uk
      #   ]
      # }
      (module.environment.domains.public.business_unit_environment) = { # hmpps-preproduction.modernisation-platform.service.justice.gov.uk
        records = [
          # { name = "db.pp.${local.application_name}", type = "CNAME", ttl = "300", records = ["pp-oasys-db-a.oasys.hmpps-test.modernisation-platform.service.justice.gov.uk"] }, # uncomment when db in aws is set up
        ]
        # lb_alias_records = [
        #   { name = "pp.${local.application_name}", type = "A", lbs_map_key = "public" },     # pp.oasys.hmpps-preproduction.modernisation-platform.service.justice.gov.uk
        #   { name = "web.pp.${local.application_name}", type = "A", lbs_map_key = "public" }, # web.pp.oasys.hmpps-preproduction.modernisation-platform.service.justice.gov.uk
        #   { name = "db.pp.${local.application_name}", type = "A", lbs_map_key = "public" },
        # ]
      }
      #
      # internal/private
      #
      (module.environment.domains.internal.business_unit_environment) = { # hmpps-preproduction.modernisation-platform.internal
        vpc = {                                                           # this makes it a private hosted zone
          id = module.environment.vpc.id
        }
        records = [
          # { name = "db.pp.${local.application_name}", type = "CNAME", ttl = "300", records = ["pp-oasys-db-a.oasys.hmpps-preproduction.modernisation-platform.internal"] }, # uncomment when db in aws is set up
        ]
        lb_alias_records = [
          # { name = "pp.${local.application_name}", type = "A", lbs_map_key = "public" },
          # { name = "web.pp.${local.application_name}", type = "A", lbs_map_key = "public" },
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
