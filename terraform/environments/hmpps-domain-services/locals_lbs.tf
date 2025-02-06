locals {

  lbs = {

    public = {
      access_logs                      = true
      enable_cross_zone_load_balancing = true
      enable_delete_protection         = false
      force_destroy_bucket             = true
      internal_lb                      = false
      load_balancer_type               = "application"
      security_groups                  = ["public-lb", "public-lb-2"]
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
          certificate_names_or_arns = ["remote_desktop_wildcard_cert"]
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

      instance_target_groups = {
        http = {
          port     = 80
          protocol = "HTTP"
          health_check = {
            enabled             = true
            interval            = 10
            healthy_threshold   = 3
            matcher             = "200-399"
            path                = "/"
            port                = 80
            protocol            = "HTTP"
            timeout             = 5
            unhealthy_threshold = 2
          }
          stickiness = {
            enabled = true
            type    = "lb_cookie"
          }
          target_type = "instance"
        }
        https = {
          port     = 443
          protocol = "HTTPS"
          health_check = {
            enabled             = true
            interval            = 10
            healthy_threshold   = 3
            matcher             = "200-399"
            path                = "/"
            port                = 443
            protocol            = "HTTPS"
            timeout             = 5
            unhealthy_threshold = 2
          }
          stickiness = {
            enabled = true
            type    = "lb_cookie"
          }
          target_type = "instance"
        }
      }
    }
  }
}
