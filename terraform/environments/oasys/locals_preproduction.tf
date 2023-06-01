# environment specific settings
locals {
  preproduction_config = {
    ec2_common = {
      patch_approval_delay_days = 3
      patch_day                 = "TUE"
    }

    baseline_acm_certificates = {
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

            }
          }
        }
      }
    }

    baseline_route53_zones = {
      "pp.${module.environment.domains.public.short_name}" = { # "pp.oasys.service.justice.gov.uk"
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

