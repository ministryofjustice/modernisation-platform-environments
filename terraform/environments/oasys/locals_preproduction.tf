# environment specific settings
locals {
  preproduction_config = {
    ec2_common = {
      patch_approval_delay_days = 3
      patch_day                 = "TUE"
    }

    baseline_ec2_instances = {
    }

    baseline_ec2_autoscaling_groups = {
      # "pp-${local.application_name}-db-a" = merge(local.database_a, {
      #   user_data_cloud_init  = merge(module.baseline_presets.ec2_instance.user_data_cloud_init.ssm_agent_ansible_no_tags, {
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

    baseline_acm_certificates = {
      "pp_${local.application_name}_cert" = {
        # domain_name limited to 64 chars so use modernisation platform domain for this
        # and put the wildcard in the san
        domain_name = "pp.oasys.service.justice.gov.uk"
        subject_alternate_names = [
          "*.oasys.service.justice.gov.uk",
          "*.az.justice.gov.uk",
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
      private = {
        internal_lb              = true
        enable_delete_protection = false
        existing_target_groups   = {}
        idle_timeout             = 60 # 60 is deafult
        security_groups          = ["private_lb"]
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
      # "pp.${module.environment.domains.public.short_name}" = { # "pp.oasys.service.justice.gov.uk"
      #   records = [
      #     { name = "db", type = "A", ttl = "300", records = ["10.40.40.133"] }, # "db.pp.oasys.service.justice.gov.uk" currently pointing to azure db PPODL00009
      #   ]
      #   # lb_alias_records = [
      #   #   { name = "web", type = "A", lbs_map_key = "private" }, # "web.pp.oasys.service.justice.gov.uk"
      #   # ]
      # }
    }

  }
}

