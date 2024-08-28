locals {

  lbs = {

    private = {
      enable_delete_protection = false
      force_destroy_bucket     = true
      idle_timeout             = 240
      internal_lb              = true
      subnets                  = module.environment.subnets["private"].ids
      security_groups          = ["private-lb"]

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
          cloudwatch_metric_alarms = module.baseline_presets.cloudwatch_metric_alarms.lb
          port                     = 443
          protocol                 = "HTTPS"
          ssl_policy               = "ELBSecurityPolicy-2016-08"

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
