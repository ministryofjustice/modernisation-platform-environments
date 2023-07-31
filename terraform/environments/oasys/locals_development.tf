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
      "dev-${local.application_name}-db-a" = local.database_a

    }

    baseline_ec2_autoscaling_groups = {

      # "dev-${local.application_name}-db-b" = merge(local.database_b, {
      #   autoscaling_schedules = module.baseline_presets.ec2_autoscaling_schedules.working_hours
      #   tags                  = local.database_tags
      # })

      # "dev-${local.application_name}-web-a" = local.webserver_a

      # "dev-${local.application_name}-bip-a" = local.bip_a
    }

    baseline_acm_certificates = {
      # "dev_${local.application_name}_cert" = {
      #   # domain_name limited to 64 chars so use modernisation platform domain for this
      #   # and put the wildcard in the san
      #   domain_name = "dev.oasys.service.justice.gov.uk"
      #   subject_alternate_names = [
      #     "*.dev.oasys.service.justice.gov.uk",
      #     "dev-oasys.hmpp-azdt.justice.gov.uk",
      #   ]
      #   external_validation_records_created = true
      #   cloudwatch_metric_alarms            = module.baseline_presets.cloudwatch_metric_alarms_lists_with_actions["dso_pagerduty"].acm_default
      #   tags = {
      #     description = "cert for ${local.application_name} ${local.environment} domains"
      #   }
      # }
    }

    baseline_lbs = {
      # external = {
      #   load_balancer_type       = "network"
      #   internal_lb              = false
      #   access_logs              = false # NLB don't have access logs unless they have a tls listener
      #   # force_destroy_bucket     = true
      #   # s3_versioning            = false
      #   enable_delete_protection = false
      #   existing_target_groups = {
      #     "internal-lb-https-443" = {
      #       arn = length(aws_lb_target_group.internal-lb-https-443) > 0 ? aws_lb_target_group.internal-lb-https-443[0].arn : ""
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
      #         target_group_name = "internal-lb-https-443"
      #       }
      #     }
      #   }
      # }

      # internal = {
      #   internal_lb = true
      #   access_logs              = false
      #   # s3_versioning            = false
      #   force_destroy_bucket     = true
      #   enable_delete_protection = false
      #   existing_target_groups   = {}
      #   idle_timeout             = 60 # 60 is default
      #   security_groups          = ["private_lb_internal", "private_lb_external"]
      #   public_subnets           = module.environment.subnets["public"].ids
      #   tags                     = local.tags

      #   listeners = {
      #     https = {
      #       port                      = 443
      #       protocol                  = "HTTPS"
      #       ssl_policy                = "ELBSecurityPolicy-2016-08"
      #       certificate_names_or_arns = ["dev_${local.application_name}_cert"]
      #       default_action = {
      #         type = "fixed-response"
      #         fixed_response = {
      #           content_type = "text/plain"
      #           message_body = "use dev.oasys.service.justice.gov.uk"
      #           status_code  = "200"
      #         }
      #       }
      #       rules = {
      #         dev-web-http-8080 = {
      #           priority = 100
      #           actions = [{
      #             type              = "forward"
      #             target_group_name = "dev-${local.application_name}-web-a-http-8080"
      #           }]
      #           conditions = [
      #             {
      #               host_header = {
      #                 values = [
      #                   "dev.oasys.service.justice.gov.uk",
      #                   "*.dev.oasys.service.justice.gov.uk",
      #                   "dev-oasys.hmpp-azdt.justice.gov.uk",
      #                 ]
      #               }
      #             }
      #           ]
      #         }
      #       }
      #     }
      #   }
      # }
    }

    baseline_route53_zones = {
      #
      # public
      #
      # "${local.application_name}.service.justice.gov.uk" = {
      #   lb_alias_records = [
      #     # { name = "dev", type = "A", lbs_map_key = "external" }, # dev.oasys.service.justice.gov.uk # need to add an ns record to oasys.service.justice.gov.uk -> dev, 
      #     # { name = "db.dev", type = "A", lbs_map_key = "external" },  # db.dev.oasys.service.justice.gov.uk currently pointing to azure db T2ODL0009
      #   ]
      # }
      # (module.environment.domains.public.business_unit_environment) = { # hmpps-test.modernisation-platform.service.justice.gov.uk
      #   # lb_alias_records = [
      #   # ]
      # }
      # #
      # # internal/private
      # #
      # (module.environment.domains.internal.business_unit_environment) = { # hmpps-test.modernisation-platform.internal
      #   vpc = {                                                           # this makes it a private hosted zone
      #     id = module.environment.vpc.id
      #   }
      #   records = [
      #     # { name = "db.dev.${local.application_name}", type = "A", ttl = "300", records = ["10.101.36.132"] }, # db.dev.oasys.hmpps-test.modernisation-platform.internal currently pointing to azure db T2ODL0009
      #   ]
      #   lb_alias_records = [
      #   ]
      # }
    }
  }
}
