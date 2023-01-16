locals {

  lb_listener_defaults = {
    environment_external_dns_zone = {
      account                = "core-vpc"
      zone_id                = data.aws_route53_zone.external-environment.zone_id
      evaluate_target_health = true
    }
    nomis_web_http = {
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
    nomis_web_https = {
      lb_application_name = "nomis-public"
      port                = 443
      protocol            = "HTTPS"
      ssl_policy          = "ELBSecurityPolicy-2016-08"
      certificate_arns    = [module.acm_certificate[local.certificate.modernisation_platform_wildcard.name].arn]
      default_action = {
        type = "fixed-response"
        fixed_response = {
          content_type = "text/plain"
          message_body = "Fixed response content"
          status_code  = "503"
        }
      }
      target_groups = {
        http-7777 = {
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
      }
      rules = {
        forward-http-7777 = {
          actions = [{
            type              = "forward"
            target_group_name = "http-7777"
          }]
          conditions = [{
            host_header = {
              values = ["*.nomis.${data.aws_route53_zone.external.name}"]
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
      t1-nomis-web-http = local.lb_listener_defaults.nomis_web_http

      t1-nomis-web-https = merge(local.lb_listener_defaults.nomis_web_https, {
        route53_records = {
          "t1-nomis-web.nomis" = local.lb_listener_defaults.environment_external_dns_zone
        }
      })
    }

    preproduction = {}
    production    = {}
  }
}
