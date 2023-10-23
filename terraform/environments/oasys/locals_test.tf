# environment specific settings
locals {
  test_config = {

    ec2_common = {
      patch_approval_delay_days = 3
      patch_day                 = "TUE"
    }

    baseline_s3_buckets = {
    }

    baseline_ssm_parameters = {
      "/oracle/database/T1OASYS"  = local.database_ssm_parameters
      "/oracle/database/T1OASREP" = local.database_ssm_parameters
      "/oracle/database/T1AZBIPI" = local.database_ssm_parameters
      "/oracle/database/T1MISTRN" = local.database_ssm_parameters
      "/oracle/database/T1ONRSYS" = local.database_ssm_parameters
      "/oracle/database/T1ONRAUD" = local.database_ssm_parameters
      "/oracle/database/T1ONRBDS" = local.database_ssm_parameters

      "/oracle/database/T2OASYS"  = local.database_ssm_parameters
      "/oracle/database/T2OASREP" = local.database_ssm_parameters
      "/oracle/database/T2AZBIPI" = local.database_ssm_parameters
      "/oracle/database/T2MISTRN" = local.database_ssm_parameters
      "/oracle/database/T2ONRSYS" = local.database_ssm_parameters
      "/oracle/database/T2ONRAUD" = local.database_ssm_parameters
      "/oracle/database/T2ONRBDS" = local.database_ssm_parameters
    }
    baseline_secretsmanager_secrets = {
      "/oracle/database/T1OASYS"  = local.secretsmanager_secrets_db
      "/oracle/database/T1OASREP" = local.secretsmanager_secrets_db
      "/oracle/database/T1AZBIPI" = local.secretsmanager_secrets_db
      "/oracle/database/T1MISTRN" = local.secretsmanager_secrets_db
      "/oracle/database/T1ONRSYS" = local.secretsmanager_secrets_db
      "/oracle/database/T1ONRAUD" = local.secretsmanager_secrets_db
      "/oracle/database/T1ONRBDS" = local.secretsmanager_secrets_db

      "/oracle/database/T2OASYS"  = local.secretsmanager_secrets_db
      "/oracle/database/T2OASREP" = local.secretsmanager_secrets_db
      "/oracle/database/T2AZBIPI" = local.secretsmanager_secrets_db
      "/oracle/database/T2MISTRN" = local.secretsmanager_secrets_db
      "/oracle/database/T2ONRSYS" = local.secretsmanager_secrets_db
      "/oracle/database/T2ONRAUD" = local.secretsmanager_secrets_db
      "/oracle/database/T2ONRBDS" = local.secretsmanager_secrets_db

      "/database/t1/T1OASYS" = {
        secrets = {
          apex_listenerpassword    = {}
          apex_public_userpassword = {}
          apex_rest_publicpassword = {}
        }
      }
      "/database/t2/T2OASYS" = {
        secrets = {
          apex_listenerpassword    = {}
          apex_public_userpassword = {}
          apex_rest_publicpassword = {}
        }
      }
      "/database/t2-oasys-db-a/T2BIPINF" = {
        secrets = {
          systempassword = {}
        }
      }
      "/ec2/t1-oasys-db-a" = {
        secrets = {
          asm-passwords = {}
        }
      }
      "/ec2/t2-oasys-db-a" = {
        secrets = {
          asm-passwords = {}
        }
      }
      "/weblogic/test-oasys-bip-b" = {
        secrets = {
          admin_password     = {}
          admin_username     = {}
          biplatformpassword = {}
          db_username        = {}
          mdspassword        = {}
          syspassword        = {}
        }
      }
      "" = {
        postfix = ""
        secrets = {
          account_ids                       = {}
          ec2-user_pem                      = {}
          environment_management_arn        = {}
          modernisation_platform_account_id = {}
        }
      }
    }

    baseline_ec2_instances = {
      ##
      ## T2
      ##
      "t2-${local.application_name}-db-a" = merge(local.database_a, {
        tags = merge(local.database_a.tags, {
          description                             = "t2 ${local.application_name} database"
          "${local.application_name}-environment" = "t2"
          instance-scheduling                     = "skip-scheduling"
        })
      })
      "t2-${local.application_name}-db-b" = merge(local.database_b, {
        user_data_cloud_init  = merge(module.baseline_presets.ec2_instance.user_data_cloud_init.ssm_agent_ansible_no_tags, {
          args = merge(module.baseline_presets.ec2_instance.user_data_cloud_init.ssm_agent_ansible_no_tags.args, {
            branch = "secretsmanagersecrets-for-oracle19c"
          })
        })
        tags = merge(local.database_b.tags, {
          description                             = "t2 ${local.application_name} database"
          "${local.application_name}-environment" = "t2"
        })
      })

      ##
      ## T1
      ##
      "t1-${local.application_name}-db-a" = merge(local.database_a, {
        tags = merge(local.database_a.tags, {
          description                             = "t1 ${local.application_name} database"
          "${local.application_name}-environment" = "t1"
        })
      })
    }

    baseline_ec2_autoscaling_groups = {
      ##
      ## T2
      ##
      "t2-${local.application_name}-web-a" = merge(local.webserver_a, {
        config = merge(module.baseline_presets.ec2_instance.config.default, {
          ami_name                  = "oasys_webserver_release_*"
          ssm_parameters_prefix     = "ec2-web-t2/"
          iam_resource_names_prefix = "ec2-web-t2"
        })
        tags = merge(local.webserver_a.tags, {
          description                             = "t2 ${local.application_name} web"
          "${local.application_name}-environment" = "t2"
          oracle-db-hostname                      = "db.t2.oasys.hmpps-test.modernisation-platform.internal"
          oracle-db-sid                           = "T2OASYS" # for each env using azure DB will need to be OASPROD
        })
      })
      # "t2-${local.application_name}-web-b" = merge(local.webserver_b, {
      #   config = merge(module.baseline_presets.ec2_instance.config.default, {
      #     ami_name                  = "oasys_webserver_release_*"
      #     ssm_parameters_prefix     = "ec2-web-t2/"
      #     iam_resource_names_prefix = "ec2-web-t2"
      #   })
      #   user_data_cloud_init  = merge(module.baseline_presets.ec2_instance.user_data_cloud_init.ssm_agent_ansible_no_tags, {
      #     args = merge(module.baseline_presets.ec2_instance.user_data_cloud_init.ssm_agent_ansible_no_tags.args, {
      #       branch = "oasys/web-index-html-updation"
      #     })
      #   })
      #   autoscaling_group  = module.baseline_presets.ec2_autoscaling_group.cold_standby
      #   tags = merge(local.webserver_a.tags, {
      #     description                             = "t2 ${local.application_name} web"
      #     "${local.application_name}-environment" = "t2"
      #     oracle-db-hostname                      = "db.t2.oasys.hmpps-test.modernisation-platform.internal"
      #   })
      # })

      ##
      ## T1
      ##
      "t1-${local.application_name}-web-a" = merge(local.webserver_a, {
        config = merge(module.baseline_presets.ec2_instance.config.default, {
          ami_name                  = "oasys_webserver_release_*"
          ssm_parameters_prefix     = "ec2-web-t1/"
          iam_resource_names_prefix = "ec2-web-t1"
        })
        tags = merge(local.webserver_a.tags, {
          description                             = "t1 ${local.application_name} web"
          "${local.application_name}-environment" = "t1"
          oracle-db-hostname                      = "db.t1.oasys.hmpps-test.modernisation-platform.internal"
          oracle-db-sid                           = "T1OASYS" # for each env using azure DB will need to be OASPROD
        })
      })

      ##
      ## test
      ##
      # "test-${local.application_name}-bip-a" = merge(local.bip_a, {
      #   autoscaling_schedules = {}
      #   tags = merge(local.bip_a.tags, {
      #     oracle-db-hostname-a = "t2-oasys-db-a"
      #     oracle-db-hostname-b = "t2-oasys-db-b"
      #     oracle-db-name       = "T2BIPINF"
      #   })
      # })

      "test-${local.application_name}-bip-b" = merge(local.bip_b, {
        autoscaling_schedules = {}
        tags = merge(local.bip_b.tags, {
          oracle-db-hostname-a = "t2-oasys-db-a"
          oracle-db-hostname-b = "t2-oasys-db-b"
          oracle-db-name       = "T2BIPINF"
        })
      })

    }

    # If your DNS records are in Fix 'n' Go, setup will be a 2 step process, see the acm_certificate module readme
    # if making changes, comment out the listeners that use the cert, edit the cert, recreate the listeners
    baseline_acm_certificates = {
      "t2_${local.application_name}_cert" = {
        # domain_name limited to 64 chars so use modernisation platform domain for this
        # and put the wildcard in the san
        domain_name = "t2.oasys.service.justice.gov.uk"
        subject_alternate_names = [
          "*.oasys.service.justice.gov.uk",
          "*.hmpp-azdt.justice.gov.uk",
          "ords.t2.oasys.service.justice.gov.uk",
          "ords.t1.oasys.service.justice.gov.uk",
        ]
        external_validation_records_created = true
        cloudwatch_metric_alarms            = module.baseline_presets.cloudwatch_metric_alarms.acm
        tags = {
          description = "cert for t2 ${local.application_name} ${local.environment} domains"
        }
      }
    }

    # options for LBs https://docs.google.com/presentation/d/1RpXpfNY_hw7FjoMw0sdMAdQOF7kZqLUY6qVVtLNavWI/edit?usp=sharing
    baseline_lbs = {
      # public = { # just left here to see how to set up an NLB
      #   load_balancer_type       = "network"
      #   internal_lb              = false
      #   access_logs              = false # NLB don't have access logs unless they have a tls listener
      #   # force_destroy_bucket     = true
      #   # s3_versioning            = false
      #   enable_delete_protection = false
      #   existing_target_groups = {
      #     "private-lb-https-443" = {
      #       arn = length(aws_lb_target_group.private-lb-https-443) > 0 ? aws_lb_target_group.private-lb-https-443[0].arn : ""
      #     }
      #   }
      #   idle_timeout    = 60 # 60 is default
      #   security_groups = [] # no security groups for network load balancers
      #   public_subnets  = module.environment.subnets["public"].ids
      #   tags            = local.tags
      #   listeners = {
      #     https = {
      #       port     = 443
      #       protocol = "TCP"
      #       default_action = {
      #         type              = "forward"
      #         target_group_name = "private-lb-https-443"
      #       }
      #     }
      #   }
      # }

      public = {
        internal_lb              = false
        access_logs              = false
        force_destroy_bucket     = true
        enable_delete_protection = false
        existing_target_groups = {
        }
        idle_timeout    = 60 # 60 is default
        security_groups = ["public_lb"]
        public_subnets  = module.environment.subnets["public"].ids
        tags            = local.tags

        listeners = {
          https = {
            port                      = 443
            protocol                  = "HTTPS"
            ssl_policy                = "ELBSecurityPolicy-2016-08"
            certificate_names_or_arns = ["t2_${local.application_name}_cert"]
            default_action = {
              type = "fixed-response"
              fixed_response = {
                content_type = "text/plain"
                message_body = "T2 - use t2.oasys.service.justice.gov.uk, T1 - use t1.oasys.service.justice.gov.uk"
                status_code  = "200"
              }
            }
            # default_action = {
            #   type              = "forward"
            #   target_group_name = "t2-${local.application_name}-web-a-pb-http-8080"
            # }
            rules = {
              t2-web-http-8080 = {
                priority = 100
                actions = [{
                  type              = "forward"
                  target_group_name = "t2-${local.application_name}-web-a-pb-http-8080"
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
              # t2-web-b-http-8080 = {
              #   priority = 200
              #   actions = [{
              #     type              = "forward"
              #     target_group_name = "t2-${local.application_name}-web-b-pb-http-8080"
              #   }]
              #   conditions = [
              #     {
              #       host_header = {
              #         values = [
              #           "t2-b.oasys.service.justice.gov.uk",
              #         ]
              #       }
              #     }
              #   ]
              # }
              t1-web-http-8080 = {
                priority = 300
                actions = [{
                  type              = "forward"
                  target_group_name = "t1-${local.application_name}-web-a-pb-http-8080"
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
        internal_lb = true
        access_logs = false
        # s3_versioning            = false
        force_destroy_bucket     = true
        enable_delete_protection = false
        existing_target_groups   = {}
        idle_timeout             = 60 # 60 is default
        security_groups          = ["private_lb"]
        public_subnets           = module.environment.subnets["private"].ids
        tags                     = local.tags
        listeners = {
          https = {
            port                      = 443
            protocol                  = "HTTPS"
            ssl_policy                = "ELBSecurityPolicy-2016-08"
            certificate_names_or_arns = ["t2_${local.application_name}_cert"]
            default_action = {
              type = "fixed-response"
              fixed_response = {
                content_type = "text/plain"
                message_body = "T2 - use t2-int.oasys.service.justice.gov.uk, T1 - use t1-int.oasys.service.justice.gov.uk"
                status_code  = "200"
              }
            }
            # default_action = {
            #   type              = "forward"
            #   target_group_name = "t2-${local.application_name}-web-a-pv-http-8080"
            # }
            rules = {
              t2-web-http-8080 = {
                priority = 100
                actions = [{
                  type              = "forward"
                  target_group_name = "t2-${local.application_name}-web-a-pv-http-8080"
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
              # t2-web-b-http-8080 = {
              #   priority = 200
              #   actions = [{
              #     type              = "forward"
              #     target_group_name = "t2-${local.application_name}-web-b-pv-http-8080"
              #   }]
              #   conditions = [
              #     {
              #       host_header = {
              #         values = [
              #           "t2-b-int.oasys.service.justice.gov.uk",
              #         ]
              #       }
              #     }
              #   ]
              # }
              t1-web-http-8080 = {
                priority = 300
                actions = [{
                  type              = "forward"
                  target_group_name = "t1-${local.application_name}-web-a-pv-http-8080"
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


    # The following zones can be found on azure:
    # az.justice.gov.uk
    # oasys.service.justice.gov.uk
    baseline_route53_zones = {
      #
      # public
      #
      # "${local.application_name}.service.justice.gov.uk" = {
      #   lb_alias_records = [
      # { name = "t2", type = "A", lbs_map_key = "public" }, # t2.oasys.service.justice.gov.uk # need to add an ns record to oasys.service.justice.gov.uk -> t2, 
      # { name = "db.t2", type = "A", lbs_map_key = "public" },  # db.t2.oasys.service.justice.gov.uk currently pointing to azure db T2ODL0009
      #   ]
      # }
      # "t1.${local.application_name}.service.justice.gov.uk" = {
      #   lb_alias_records = [
      #     { name = "web", type = "A", lbs_map_key = "public" }, # web.t1.oasys.service.justice.gov.uk # need to add an ns record to oasys.service.justice.gov.uk -> t1, 
      #     { name = "db", type = "A", lbs_map_key = "public" },
      #   ]
      # }
      (module.environment.domains.public.business_unit_environment) = { # hmpps-test.modernisation-platform.service.justice.gov.uk
        records = [
          { name = "db.t2.${local.application_name}", type = "CNAME", ttl = "300", records = ["t2-oasys-db-a.oasys.hmpps-test.modernisation-platform.service.justice.gov.uk"] },
          { name = "db.t1.${local.application_name}", type = "CNAME", ttl = "300", records = ["t1-oasys-db-a.oasys.hmpps-test.modernisation-platform.service.justice.gov.uk"] },
        ]
        # lb_alias_records = [
        #   { name = "t2.${local.application_name}", type = "A", lbs_map_key = "public" },     # t2.oasys.hmpps-test.modernisation-platform.service.justice.gov.uk
        #   { name = "web.t2.${local.application_name}", type = "A", lbs_map_key = "public" }, # web.t2.oasys.hmpps-test.modernisation-platform.service.justice.gov.uk
        #   { name = "db.t2.${local.application_name}", type = "A", lbs_map_key = "public" },
        #   { name = "db.t1.${local.application_name}", type = "A", lbs_map_key = "public" },
        # ]
      }
      #
      # internal/private
      #
      (module.environment.domains.internal.business_unit_environment) = { # hmpps-test.modernisation-platform.internal
        vpc = {                                                           # this makes it a private hosted zone
          id = module.environment.vpc.id
        }
        records = [
          { name = "db.t2.${local.application_name}", type = "CNAME", ttl = "300", records = ["t2-oasys-db-a.oasys.hmpps-test.modernisation-platform.internal"] },
          { name = "db.t1.${local.application_name}", type = "CNAME", ttl = "300", records = ["t1-oasys-db-a.oasys.hmpps-test.modernisation-platform.internal"] },
        ]
        lb_alias_records = [
          # { name = "t2.${local.application_name}", type = "A", lbs_map_key = "public" },
          # { name = "web.t2.${local.application_name}", type = "A", lbs_map_key = "public" },
          # { name = "t1.${local.application_name}", type = "A", lbs_map_key = "public" },
          # { name = "web.t1.${local.application_name}", type = "A", lbs_map_key = "public" },
        ]
      }
    }
  }
}
