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
      "hmpps-test.modernisation-platform.service.justice.gov.uk" = {
        lb_alias_records = [
          { name = "rdgateway.hmpps-domain-services", type = "A", lbs_map_key = "public" },
          { name = "rdweb.hmpps-domain-services", type = "A", lbs_map_key = "public" },
        ]
      }
    }
  }
}

