locals {

  lbs = {

    private = {
      enable_delete_protection = false
      force_destroy_bucket     = true
      idle_timeout             = 240
      internal_lb              = true
      subnets                  = module.environment.subnets["private"].ids
      security_groups          = ["private-lb"]

      s3_notification_queues = {
        "cortex-xsiam-s3-log-collection" = {
          events    = ["s3:ObjectCreated:*"]
          queue_arn = "cortex-xsiam-s3-log-collection"
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
