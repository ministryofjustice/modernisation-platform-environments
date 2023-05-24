# environment specific settings
locals {
  development_config = {

    ec2_common = {
      patch_approval_delay_days = 3
      patch_day                 = "TUE"
    }

    baseline_bastion_linux = {
      # public_key_data = local.public_key_data.keys[local.environment]
      # tags            = local.tags
    }


    baseline_s3_buckets = {

    }

    baseline_ec2_instances = {
    }

    baseline_ec2_autoscaling_groups = {

      "dev-${local.application_name}-db" = merge(local.database, {
        autoscaling_schedules = module.baseline_presets.ec2_autoscaling_schedules.working_hours
        tags                  = local.database_tags
      })

      "${local.application_name}-web" = merge(local.webserver, {
        config = merge(module.baseline_presets.ec2_instance.config.default, {
          ami_name = "oasys_webserver_release_*"
        })
        tags = merge(local.webserver.tags, {
          description = "${local.application_name} web"
        })
      })
    }

    baseline_acm_certificates = {
      "${local.application_name}_wildcard_cert_02" = {
        # Domain_name limited to 64 chars so use modernisation platform domain
        # for this and put the wildcard in the san.
        domain_name = module.environment.domains.public.modernisation_platform
        subject_alternate_names = [
          # *.oasys.hmpps-development.modernisation-platform.service.justice.gov.uk
          "*.${module.environment.domains.public.application_environment}",
          # web.oasys.hmpps-development.modernisation-platform.service.justice.gov.uk
          "web.${module.environment.domains.public.application_environment}",
        ]
        external_validation_records_created = true
        cloudwatch_metric_alarms            = module.baseline_presets.cloudwatch_metric_alarms_lists_with_actions["dso_pagerduty"].acm_default
        tags = {
          description = "Web cert for ${local.application_name} ${local.environment} domains"
        }
      }
    }

    baseline_lbs = {

      private = {
        internal_lb              = true
        enable_delete_protection = false
        existing_target_groups   = {}
        idle_timeout             = 60 # 60 is default
        security_groups          = ["private"]
        public_subnets           = module.environment.subnets["private"].ids
        tags                     = local.tags

        listeners = {
          https = {
            port                      = 443
            protocol                  = "HTTPS"
            ssl_policy                = "ELBSecurityPolicy-2016-08"
            certificate_names_or_arns = ["${local.application_name}_wildcard_cert_02"]
            # cloudwatch_metric_alarms  = module.baseline_presets.cloudwatch_metric_alarms_lists_with_actions["dso_pagerduty"].lb_default

            default_action = {
              type = "fixed-response"
              fixed_response = {
                content_type = "text/plain"
                message_body = "Not implemented"
                status_code  = "501"
              }
            }
            rules = {
              web-http-8080 = {
                priority = 100
                actions = [{
                  type              = "forward"
                  target_group_name = "${local.application_name}-web-http-8080"
                }]
                conditions = [
                  {
                    host_header = {
                      values = [
                        # web-oasys.hmpps-development.modernisation-platform.service.justice.gov.uk
                        "web-${module.environment.domains.public.application_environment}",
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

      # hmpps-development.modernisation-platform.service.justice.gov.uk
      (module.environment.domains.public.business_unit_environment) = {
        lb_alias_records = [
          { name = "web.${local.application_name}", type = "A", lbs_map_key = "private" },
        ]
      }
    }
  }
}
