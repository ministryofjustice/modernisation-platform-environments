locals {

  lb_listener_defaults = {
    nomis_public = {
      lb_application_name = "nomis-public"
    }
    nomis_internal = {
      lb_application_name = "nomis-internal"
    }
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
      certificate_arns = [module.acm_certificate["star.${module.environment.domains.public.application_environment}"].arn]
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

  lb_listeners = {

    #--------------------------------------------------------------------------
    # define environment specific load balancer listeners here
    #--------------------------------------------------------------------------
    development = {}

    test = {
      nomis-internal-t1-nomis-web-http-7001 = merge(
        local.lb_listener_defaults.http-7001,
        local.lb_listener_defaults.nomis_internal, {
          replace = {
            target_group_name_replace     = "t1-nomis-web-internal"
            condition_host_header_replace = "t1-nomis-web-internal"
          }
        }
      )
      nomis-internal-t1-nomis-web-http-7777 = merge(
        local.lb_listener_defaults.http-7777,
        local.lb_listener_defaults.nomis_internal, {
          replace = {
            target_group_name_replace     = "t1-nomis-web-internal"
            condition_host_header_replace = "t1-nomis-web-internal"
          }
        }
      )
      nomis-internal-t1-nomis-web-https = merge(
        local.lb_listener_defaults.https,
        local.lb_listener_defaults.nomis_internal,
        local.lb_listener_defaults.route53, {
          replace = {
            target_group_name_replace     = "t1-nomis-web-internal"
            condition_host_header_replace = "t1-nomis-web-internal"
            route53_record_name_replace   = "t1-nomis-web-internal"
          }
      })

      nomis-public-t1-nomis-web-http-7001 = merge(
        local.lb_listener_defaults.http-7001,
        local.lb_listener_defaults.nomis_public, {
          replace = {
            target_group_name_replace     = "t1-nomis-web-public"
            condition_host_header_replace = "t1-nomis-web"
          }
        }
      )
      nomis-public-t1-nomis-web-http-7777 = merge(
        local.lb_listener_defaults.http-7777,
        local.lb_listener_defaults.nomis_public, {
          replace = {
            target_group_name_replace     = "t1-nomis-web-public"
            condition_host_header_replace = "t1-nomis-web"
          }
        }
      )
      nomis-public-t1-nomis-web-https = merge(
        local.lb_listener_defaults.https,
        local.lb_listener_defaults.nomis_public,
        local.lb_listener_defaults.route53, {
          replace = {
            target_group_name_replace     = "t1-nomis-web-public"
            condition_host_header_replace = "t1-nomis-web"
            route53_record_name_replace   = "t1-nomis-web"
          }
      })
    }

    preproduction = {}
    production    = {}
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
