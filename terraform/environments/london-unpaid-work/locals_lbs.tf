locals {
  lbs = {
    api-alb = {
      access_logs                      = true
      enable_cross_zone_load_balancing = true
      enable_delete_protection         = false # TODO: Set this to true once POC phase is complete.
      force_destroy_bucket             = true
      idle_timeout                     = 3600
      internal_lb                      = false # TODO - API LB, is this supposed to be private or public? Old branch indicates public
      load_balancer_type               = "application"
      security_groups                  = ["london-unpaid-work-alb"]
      subnets                          = module.environment.subnets["public"].ids

      listeners = {
        /*
        TODO: Review the below when ACM certificates are added
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
          cloudwatch_metric_alarms = module.baseline_presets.cloudwatch_metric_alarms.lb
          port                     = 443
          protocol                 = "HTTPS"
          ssl_policy               = "ELBSecurityPolicy-TLS13-1-2-2021-06"

          default_action = {
            type = "fixed-response"
            fixed_response = {
              content_type = "text/plain"
              message_body = "Access Denied"
              status_code  = "403"
            }
          }
         */
        http = {
          cloudwatch_metric_alarms = module.baseline_presets.cloudwatch_metric_alarms.lb
          port                     = 80
          protocol                 = "HTTP"

          default_action = {
            type = "fixed-response"
            fixed_response = {
              content_type = "text/plain"
              message_body = "Access Denied"
              status_code  = "403"
            }
          }
        }
      }

      instance_target_groups = {
        api-http-80 = {
          port     = 80
          protocol = "HTTP"
          health_check = {
            enabled             = true
            healthy_threshold   = 3
            interval            = 30
            matcher             = "200-399"
            path                = "/karma.html" # legacy API health check path
            port                = 80
            timeout             = 5
            unhealthy_threshold = 5
          }
          stickiness = {
            enabled = true
            type    = "lb_cookie"
          }
        }
      }
    }

    web-alb = {
      access_logs                      = true
      enable_cross_zone_load_balancing = true
      enable_delete_protection         = false # TODO: Set this to true once POC phase is complete.
      force_destroy_bucket             = true
      idle_timeout                     = 3600
      internal_lb                      = false
      load_balancer_type               = "application"
      security_groups                  = ["london-unpaid-work-alb"]
      subnets                          = module.environment.subnets["public"].ids

      listeners = {
        /* TODO: Review the below when ACM certificates are added
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
          port                      = 443
          protocol                  = "HTTPS"
          ssl_policy                = "ELBSecurityPolicy-TLS13-1-2-2021-06"

          default_action = {
            type = "fixed-response"
            fixed_response = {
              content_type = "text/plain"
              message_body = "Access Denied"
              status_code  = "403"
            }
          }
        }*/
        http = {
          cloudwatch_metric_alarms = module.baseline_presets.cloudwatch_metric_alarms.lb
          port                     = 80
          protocol                 = "HTTP"

          default_action = {
            type = "fixed-response"
            fixed_response = {
              content_type = "text/plain"
              message_body = "Access Denied"
              status_code  = "403"
            }
          }
        }
      }

      instance_target_groups = {
        web-http-80 = {
          port     = 80
          protocol = "HTTP"
          health_check = {
            enabled             = true
            healthy_threshold   = 3
            interval            = 30
            matcher             = "200-399"
            path                = "/index.html" # legacy API health check path
            port                = 80
            timeout             = 5
            unhealthy_threshold = 5
          }
          stickiness = {
            enabled = true
            type    = "lb_cookie"
          }
        }
      }
    }
  }
}
