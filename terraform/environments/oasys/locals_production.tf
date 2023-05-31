# environment specific settings
locals {
  production_config = {

    ec2_common = {
      patch_approval_delay_days = 7
      patch_day                 = "THU"
    }

    baseline_bastion_linux = {
      public_key_data = local.public_key_data.keys[local.environment]
      tags            = local.tags
    }

    baseline_ec2_autoscaling_groups = {
      "prod-${local.application_name}-web-trn-a" = merge(local.webserver_a, {
        config = merge(module.baseline_presets.ec2_instance.config.default, {
          ami_name                  = "${local.application_name}_webserver_release_*"
          ssm_parameters_prefix     = "ec2-web-trn/"
          iam_resource_names_prefix = "ec2-web-trn"
        })
        tags = merge(local.webserver_a.tags, {
          description                             = "${local.environment} training ${local.application_name} web"
          "${local.application_name}-environment" = "trn"
          oracle-db-sid                           = "OASTRN"
        })
      })
    }

    baseline_acm_certificates = {
    }

    baseline_lbs = {
      private = {
        enable_delete_protection = false # change to true before we actually use
        force_destroy_bucket     = false
        idle_timeout             = "60"
        internal_lb              = true
        security_groups          = ["private"]
        public_subnets           = module.environment.subnets["private"].ids
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
              # web-http-8080 = {
              #   priority = 100
              #   actions = [{
              #     type              = "forward"
              #     target_group_name = "prod-${local.application_name}-web-a-http-8080"
              #   }]
              #   conditions = [
              #     {
              #       host_header = {
              #         values = ["${module.environment.domains.public.short_name}"]
              #       }
              #     },
              #     {
              #       path_pattern = {
              #         values = ["/"]
              #       }
              #     }
              #   ]
              # }
              trn-web-http-8080 = {
                priority = 100
                actions = [{
                  type              = "forward"
                  target_group_name = "prod-${local.application_name}-web-trn-a-http-8080"
                }]
                conditions = [
                  {
                    host_header = {
                      values = ["trn.${module.environment.domains.public.short_name}"]
                    }
                  },
                  {
                    path_pattern = {
                      values = ["/"]
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
      (module.environment.domains.public.short_name) = { # "oasys.service.justice.gov.uk"
        records = [
          { name = "db", type = "A", ttl = "300", records = ["10.40.6.133"] },     #     "db.oasys.service.justice.gov.uk" currently pointing to azure db PDODL00011
          { name = "trn.db", type = "A", ttl = "300", records = ["10.40.6.138"] }, # "trn.db.oasys.service.justice.gov.uk" currently pointing to azure db PDODL00019
          { name = "ptc.db", type = "A", ttl = "300", records = ["10.40.6.138"] }, # "ptc.db.oasys.service.justice.gov.uk" currently pointing to azure db PDODL00019
        ]
        lb_alias_records = [
          { name = "web", type = "A", lbs_map_key = "private" },     #     web.oasys.service.justice.gov.uk
          { name = "trn.web", type = "A", lbs_map_key = "private" }, # trn.web.oasys.service.justice.gov.uk
          { name = "ptc.web", type = "A", lbs_map_key = "private" }, # ptc.web.oasys.service.justice.gov.uk
        ]
      }
    }
  }
}
