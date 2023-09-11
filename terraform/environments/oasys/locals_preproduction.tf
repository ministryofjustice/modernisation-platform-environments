# environment specific settings
locals {
  preproduction_config = {
    ec2_common = {
      patch_approval_delay_days = 3
      patch_day                 = "TUE"
    }

    baseline_s3_buckets = {}

    baseline_ec2_instances = {
      # "pp-${local.application_name}-db-a" = merge(local.database_a, {
        # user_data_cloud_init  = merge(module.baseline_presets.ec2_instance.user_data_cloud_init.ssm_agent_ansible_no_tags, {
        #     args = merge(module.baseline_presets.ec2_instance.user_data_cloud_init.ssm_agent_ansible_no_tags.args, {
        #       branch = "oasys-db-az-backup"
        #     })
        #   })
      #   tags = merge(local.database_a.tags, {
      #     description                             = "pp ${local.application_name} database"
      #     "${local.application_name}-environment" = "pp"
      #     instance-scheduling                     = "skip-scheduling"
      #   })
      # })
    }

    baseline_ec2_autoscaling_groups = {
      "pp-${local.application_name}-db-a" = merge(local.database_a, {
        user_data_cloud_init  = merge(module.baseline_presets.ec2_instance.user_data_cloud_init.ssm_agent_ansible_no_tags, {
          args = merge(module.baseline_presets.ec2_instance.user_data_cloud_init.ssm_agent_ansible_no_tags.args, {
            branch = "oasys-db-az-backup"
          })
        })
        tags = merge(local.database_a.tags, {
          description                             = "pp ${local.application_name} database"
          "${local.application_name}-environment" = "pp"
          instance-scheduling                     = "skip-scheduling"
        })
      })
    }

    baseline_acm_certificates = {
      "pp_${local.application_name}_cert" = {
        # domain_name limited to 64 chars
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
        external_validation_records_created = true
        cloudwatch_metric_alarms            = module.baseline_presets.cloudwatch_metric_alarms.acm
        tags = {
          description = "cert for ${local.application_name} ${local.environment} domains"
        }
      }
    }

    # options for LBs https://docs.google.com/presentation/d/1RpXpfNY_hw7FjoMw0sdMAdQOF7kZqLUY6qVVtLNavWI/edit?usp=sharing
    baseline_lbs = {
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
          # https = {
          #   port                      = 443
          #   protocol                  = "HTTPS"
          #   ssl_policy                = "ELBSecurityPolicy-2016-08"
          #   certificate_names_or_arns = ["pp_${local.application_name}_cert"]
          #   default_action = {
          #     type = "fixed-response"
          #     fixed_response = {
          #       content_type = "text/plain"
          #       message_body = "PP - use pp.oasys.service.justice.gov.uk"
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
          #               "bridge-pp-oasys.az.justice.gov.uk",
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
          # https = {
          #   port                      = 443
          #   protocol                  = "HTTPS"
          #   ssl_policy                = "ELBSecurityPolicy-2016-08"
          #   certificate_names_or_arns = ["pp_${local.application_name}_cert"]
          #   default_action = {
          #     type = "fixed-response"
          #     fixed_response = {
          #       content_type = "text/plain"
          #       message_body = "PP - use pp-int.oasys.service.justice.gov.uk"
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
      # (module.environment.domains.public.business_unit_environment) = { # hmpps-preproduction.modernisation-platform.service.justice.gov.uk
      #   records = [
      #     { name = "db.pp.${local.application_name}", type = "CNAME", ttl = "300", records = ["pp-oasys-db-a.oasys.hmpps-test.modernisation-platform.service.justice.gov.uk"] },
      #   ]
      # }
      # #
      # # internal/private
      # #
      # (module.environment.domains.internal.business_unit_environment) = { # hmpps-test.modernisation-platform.internal
      #   vpc = {                                                           # this makes it a private hosted zone
      #     id = module.environment.vpc.id
      #   }
      #   records = [
      #     { name = "db.pp.${local.application_name}", type = "CNAME", ttl = "300", records = ["pp-oasys-db-a.oasys.hmpps-test.modernisation-platform.internal"] },
      #   ]
      # }
    }

  }
}
