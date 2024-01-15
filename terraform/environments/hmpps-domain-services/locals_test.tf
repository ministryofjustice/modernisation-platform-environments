locals {

  # baseline config
  test_config = {

    baseline_secretsmanager_secrets = {
      "/join_domain_linux_service_account" = {
        secrets = {
          passwords = {}
        }
      }
    }

    baseline_acm_certificates = {
      # remote_desktop_wildcard_cert = {
      #   # domain_name limited to 64 chars so use modernisation platform domain for this
      #   # and put the wildcard in the san
      #   domain_name = module.environment.domains.public.modernisation_platform
      #   subject_alternate_names = [
      #     "*.${module.environment.domains.public.application_environment}",
      #     "hmppgw1.justice.gov.uk",
      #     "*.hmppgw1.justice.gov.uk",
      #   ]
      #   external_validation_records_created = false
      #   cloudwatch_metric_alarms            = module.baseline_presets.cloudwatch_metric_alarms.acm
      #   tags = {
      #     description = "wildcard cert for remote desktop services"
      #   }
      # }
    }

    baseline_ec2_autoscaling_groups = {
    }

    baseline_ec2_instances = {
    }

    baseline_lbs = {
      public = {
        access_logs                      = true
        enable_cross_zone_load_balancing = true
        enable_delete_protection         = false
        force_destroy_bucket             = true
        internal_lb                      = false
        load_balancer_type               = "application"
        security_groups                  = ["public-lb"]
        subnets = [
          module.environment.subnet["public"]["eu-west-2a"].id,
          module.environment.subnet["public"]["eu-west-2b"].id,
        ]

        instance_target_groups = {
        }
        listeners = {
          http = {
            port     = 80
            protocol = "HTTP"
            default_action = {
              type = "redirect"
              redirect = {
                port        = 443
                protocol    = "HTTPS"
                status_code = "HTTP_301"
              }
            }
          }
          https = {
            port                      = 443
            protocol                  = "HTTPS"
            ssl_policy                = "ELBSecurityPolicy-TLS13-1-2-2021-06"
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
      "test.hmpps-domain.service.justice.gov.uk" = {
        lb_alias_records = [
          { name = "rdgateway1", type = "A", lbs_map_key = "public" },
          { name = "rdweb1", type = "A", lbs_map_key = "public" },
        ]
      }
    }
  }
}

