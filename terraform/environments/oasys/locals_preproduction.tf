# environment specific settings
locals {
  preproduction_config = {
    ec2_common = {
      patch_approval_delay_days = 3
      patch_day                 = "TUE"
    }

    baseline_acm_certificates = {
      "${local.application_name}_wildcard_cert" = {
        # domain_name limited to 64 chars so use modernisation platform domain for this
        # and put the wildcard in the san
        domain_name = module.environment.domains.public.modernisation_platform
        subject_alternate_names = [
          "*.${module.environment.domains.public.application_environment}",
          "*.pp.${module.environment.domains.public.short_name}", # "pp.oasys.service.justice.gov.uk"
          "*.pp.${local.application_name}.az.justice.gov.uk",
          "*.pp-${local.application_name}.az.justice.gov.uk",
        ]
        external_validation_records_created = true
        cloudwatch_metric_alarms            = {} # module.baseline_presets.cloudwatch_metric_alarms_lists_with_actions["dso"].acm_default
        tags = {
          description = "wildcard cert for ${local.application_name} ${local.environment} domains"
        }
      }
    }

    baseline_lbs = {
      private = {
        internal_lb              = true
        enable_delete_protection = false
        existing_target_groups   = {}
        idle_timeout             = 60 # 60 is deafult
        security_groups          = ["private"]
        public_subnets           = module.environment.subnets["private"].ids
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
              # pp-web-http-8080 = {
              #   priority = 100
              #   actions = [{
              #     type              = "forward"
              #     target_group_name = "pp-${local.application_name}-web-http-8080"
              #   }]
              #   conditions = [
              #     {
              #       host_header = {
              #         values = ["pp.${module.environment.domains.public.short_name}"]
              #       }
              #     },
              #     {
              #       path_pattern = {
              #         values = ["/"]
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
      "pp.${module.environment.domains.public.short_name}" = {  # "pp.oasys.service.justice.gov.uk"
        records = [
          { name = "db", type = "A", ttl = "300", records = ["10.40.40.133"] }, # "db.pp.oasys.service.justice.gov.uk" currently pointing to azure db PPODL00009
        ]
        # lb_alias_records = [
        #   { name = "web", type = "A", lbs_map_key = "private" }, # "web.pp.oasys.service.justice.gov.uk"
        # ]
      }
    }

    baseline_ec2_instances = {
    }

    baseline_bastion_linux = {
      public_key_data = local.public_key_data.keys[local.environment]
      tags            = local.tags
    }
  }
}

