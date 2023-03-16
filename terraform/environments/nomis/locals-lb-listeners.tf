locals {

  lb_listener_defaults = {
    route53 = {
      route53_records = {
        "$(name).nomis" = {
          account                = "core-vpc"
          zone_id                = module.environment.route53_zones[module.environment.domains.public.business_unit_environment].zone_id
          evaluate_target_health = true
        }
      }
    }

    http = {
      port     = 80
      protocol = "HTTP"
      default_action = {
        type = "redirect"
        redirect = {
          status_code = "HTTP_301"
          port        = 443
          protocol    = "HTTPS"
        }
      }
    }
    http-7001 = {
      port     = 7001
      protocol = "HTTP"
      default_action = {
        type              = "forward"
        target_group_name = "$(name)-http-7001"
      }
    }
    http-7777 = {
      port     = 7777
      protocol = "HTTP"
      default_action = {
        type              = "forward"
        target_group_name = "$(name)-http-7777"
      }
    }
    https = {
      port             = 443
      protocol         = "HTTPS"
      ssl_policy       = "ELBSecurityPolicy-2016-08"
      certificate_arns = ["application_environment_wildcard_cert"]
      default_action = {
        type = "fixed-response"
        fixed_response = {
          content_type = "text/plain"
          message_body = "Not implemented"
          status_code  = "501"
        }
      }
      rules = {
        forward-http-7001 = {
          priority = 100
          actions = [{
            type              = "forward"
            target_group_name = "$(name)-http-7001"
          }]
          conditions = [
            {
              host_header = {
                values = ["$(name).nomis.${module.environment.vpc_name}.modernisation-platform.service.justice.gov.uk"]
              }
            },
            {
              path_pattern = {
                values = ["/console", "/console/*"]
              }
          }]
        }
        forward-http-7777 = {
          priority = 200
          actions = [{
            type              = "forward"
            target_group_name = "$(name)-http-7777"
          }]
          conditions = [{
            host_header = {
              values = ["$(name).nomis.${module.environment.vpc_name}.modernisation-platform.service.justice.gov.uk"]
            }
          }]
        }
      }
    }
  }

  # allows an over-ride on where to send alarms (which sns topic) based on environment
  lb_listeners_sns_topic = {
    development = {}
    test = {
      sns_topic = aws_sns_topic.nomis_alarms.arn
    }
    preproduction = {}
    production    = {}
  }
}
