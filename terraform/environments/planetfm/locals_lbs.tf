locals {

  lbs = {

    private = {
      enable_cross_zone_load_balancing = true
      enable_delete_protection         = false
      force_destroy_bucket             = true
      idle_timeout                     = 3600
      load_balancer_type               = "application"
      internal_lb                      = true
      security_groups                  = ["loadbalancer"]
      subnets                          = module.environment.subnets["private"].ids

      instance_target_groups = {
        web-80 = {
          health_check = {
            enabled             = true
            healthy_threshold   = 3
            interval            = 30
            matcher             = "200-399"
            path                = "/"
            port                = 80
            timeout             = 5
            unhealthy_threshold = 5
          }
          port     = 80
          protocol = "HTTP"
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
          cloudwatch_metric_alarms  = module.baseline_presets.cloudwatch_metric_alarms.lb
          certificate_names_or_arns = ["planetfm_wildcard_cert"]
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

    web = {
      access_logs                      = false
      enable_cross_zone_load_balancing = true
      enable_delete_protection         = true
      force_destroy_bucket             = true
      internal_lb                      = true
      load_balancer_type               = "network"
      security_groups                  = ["loadbalancer"]
      subnets = [
        module.environment.subnet["private"]["eu-west-2a"].id,
        module.environment.subnet["private"]["eu-west-2b"].id,
      ]
      instance_target_groups = {
        https = {
          port     = 443
          protocol = "TCP"
          health_check = {
            enabled             = true
            interval            = 5
            healthy_threshold   = 3
            port                = 443
            protocol            = "TCP"
            timeout             = 4
            unhealthy_threshold = 2
          }
          stickiness = {
            enabled = true
            type    = "source_ip"
          }
        }
      }
      listeners = {
        https = {
          cloudwatch_metric_alarms = module.baseline_presets.cloudwatch_metric_alarms.network_lb
          port                     = 443
          protocol                 = "TCP"
        }
      }
    }
  }
}
