locals {

  lbs = {
    private = {
      access_logs              = true
      enable_delete_protection = false
      force_destroy_bucket     = true
      idle_timeout             = 3600 # 60 is default
      internal_lb              = true
      security_groups          = ["private_alb_sg"]
      subnets                  = module.environment.subnets["private"].ids

      listeners = {
        https = {
          cloudwatch_metric_alarms = module.baseline_presets.cloudwatch_metric_alarms.lb
          port                     = 443
          protocol                 = "HTTPS"
          ssl_policy               = "ELBSecurityPolicy-TLS13-1-2-2021-06"

          default_action = {
            type = "fixed-response"
            fixed_response = {
              content_type = "text/plain"
              message_body = "Dev - https://www.dev.victim-case-management.service.justice.gov.uk/"
              status_code  = "200"
            }
          }
        }
      }
    }
  }
}
