locals {

  lbs = {

    private = {
      enable_cross_zone_load_balancing = true
      enable_delete_protection         = false
      force_destroy_bucket             = true
      idle_timeout                     = 3600
      internal_lb                      = true
      security_groups                  = ["lb"]
      subnets                          = module.environment.subnets["private"].ids

      instance_target_groups = {
        web = {
          port     = 7777
          protocol = "HTTP"
          health_check = {
            enabled             = true
            healthy_threshold   = 3
            interval            = 30
            matcher             = "200-399"
            path                = "/"
            port                = 7777
            timeout             = 5
            unhealthy_threshold = 5
          }
          stickiness = {
            enabled = true
            type    = "lb_cookie"
          }
        }
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
          certificate_names_or_arns = ["nomis_combined_reporting_wildcard_cert"]
          cloudwatch_metric_alarms  = module.baseline_presets.cloudwatch_metric_alarms.lb
          port                      = 443
          protocol                  = "HTTPS"
          ssl_policy                = "ELBSecurityPolicy-TLS13-1-2-2021-06"

          default_action = {
            type = "fixed-response"
            fixed_response = {
              content_type = "text/plain"
              message_body = "Not implemented"
              status_code  = "501"
            }
          }
        }
      }
    }

    public = {
      # access_logs                    = true # enable this at some point
      enable_cross_zone_load_balancing = true
      enable_delete_protection         = false
      force_destroy_bucket             = true
      idle_timeout                     = 3600
      internal_lb                      = false
      security_groups                  = ["public-lb"]
      subnets                          = module.environment.subnets["public"].ids

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
          certificate_names_or_arns = ["nomis_combined_reporting_wildcard_cert"]
          cloudwatch_metric_alarms  = module.baseline_presets.cloudwatch_metric_alarms.lb
          port                      = 443
          protocol                  = "HTTPS"
          ssl_policy                = "ELBSecurityPolicy-TLS13-1-2-2021-06"

          default_action = {
            type = "fixed-response"
            fixed_response = {
              content_type = "text/plain"
              message_body = "Not implemented"
              status_code  = "501"
            }
          }
        }
      }
    }
  }
}
