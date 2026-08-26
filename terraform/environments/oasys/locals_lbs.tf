locals {

  lbs = {
    public = {
      access_logs              = true
      enable_delete_protection = false
      idle_timeout             = 240
      internal_lb              = false
      force_destroy_bucket     = true
      s3_versioning            = false
      security_groups          = ["public_lb", "public_lb_2"]
      subnets                  = module.environment.subnets["public"].ids

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
              message_body = "T2 - use t2.oasys.service.justice.gov.uk, T1 - use t1.oasys.service.justice.gov.uk"
              status_code  = "200"
            }
          }
        }
      }
    }

    private = {
      access_logs              = true
      enable_delete_protection = false
      force_destroy_bucket     = true
      idle_timeout             = 3600 # 60 is default
      internal_lb              = true
      security_groups          = ["private_lb"]
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
              message_body = "T2 - use t2-int.oasys.service.justice.gov.uk, T1 - use t1-int.oasys.service.justice.gov.uk"
              status_code  = "200"
            }
          }
        }
      }
    }
  }
}
