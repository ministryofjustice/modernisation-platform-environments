locals {

  lb_http_7001_rule = {
    port                 = 7001
    protocol             = "HTTP"
    target_type          = "instance"
    deregistration_delay = 30
    health_check = {
      enabled             = true
      interval            = 30
      healthy_threshold   = 3
      matcher             = "200-399"
      path                = "/"
      port                = 7001
      timeout             = 5
      unhealthy_threshold = 5
    }
    stickiness = {
      enabled = true
      type    = "lb_cookie"
    }
  }

  lb_http_7777_rule = {
    port                 = 7777
    protocol             = "HTTP"
    target_type          = "instance"
    deregistration_delay = 30
    health_check = {
      enabled             = true
      interval            = 30
      healthy_threshold   = 3
      matcher             = "200-399"
      path                = "/keepalive.htm"
      port                = 7777
      timeout             = 5
      unhealthy_threshold = 5
    }
    stickiness = {
      enabled = true
      type    = "lb_cookie"
    }
  }


  lb_listener_defaults = {
    environment_external_dns_zone = {
      account                = "core-vpc"
      zone_id                = data.aws_route53_zone.external-environment.zone_id
      evaluate_target_health = true
    }
    http = {
      lb_application_name = "nomis-public"
      port                = 80
      protocol            = "HTTP"
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
      lb_application_name = "nomis-public"
      port                = 7001
      protocol            = "HTTP"
      target_groups = {
        http-7001-asg = local.lb_http_7001_rule
      }
      default_action = {
        type              = "forward"
        target_group_name = "http-7001-asg"
      }
    }
    http-7777 = {
      lb_application_name = "nomis-public"
      port                = 7777
      protocol            = "HTTP"
      target_groups = {
        http-7777-asg = local.lb_http_7777_rule
      }
      default_action = {
        type              = "forward"
        target_group_name = "http-7777-asg"
      }
    }
    https = {
      lb_application_name = "nomis-public"
      port                = 443
      protocol            = "HTTPS"
      ssl_policy          = "ELBSecurityPolicy-2016-08"
      certificate_arns    = [module.acm_certificate[local.certificate.modernisation_platform_wildcard.name].arn]
      default_action = {
        type = "fixed-response"
        fixed_response = {
          content_type = "text/plain"
          message_body = "Not implemented"
          status_code  = "501"
        }
      }
      target_groups = {
        http-7001-asg = local.lb_http_7001_rule
        http-7777-asg = local.lb_http_7777_rule
      }
      rules = {
        forward-http-7001-asg = {
          priority = 100
          actions = [{
            type              = "forward"
            target_group_name = "http-7001-asg"
          }]
          conditions = [
            {
              host_header = {
                values = ["*-nomis-web.nomis.${local.vpc_name}-${local.environment}.modernisation-platform.service.justice.gov.uk"]
              }
            },
            {
              path_pattern = {
                values = ["/console", "/console/*"]
              }
          }]
        }
        forward-http-7777-asg = {
          priority = 200
          actions = [{
            type              = "forward"
            target_group_name = "http-7777-asg"
          }]
          conditions = [{
            host_header = {
              values = ["*-nomis-web.nomis.${local.vpc_name}-${local.environment}.modernisation-platform.service.justice.gov.uk"]
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
      http      = local.lb_listener_defaults.http
      http-7001 = local.lb_listener_defaults.http-7001
      http-7777 = local.lb_listener_defaults.http-7777
      https = merge(local.lb_listener_defaults.https, {
        route53_records = {
          "t1-nomis-web.nomis" = local.lb_listener_defaults.environment_external_dns_zone
        }
      })
    }

    preproduction = {}
    production    = {}
  }
}
