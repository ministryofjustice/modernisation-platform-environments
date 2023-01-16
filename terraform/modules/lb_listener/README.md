Create an `aws_lb_listener` with associated resources such as:

- `aws_lb_target_group`
- `aws_lb_target_group_attachment`
- `aws_lb_listener_rule`
- `aws_lb_listener_certificate`
- `aws_route53_record`

If associating with an `aws_autoscaling_group`, be sure to create the
load balancer resource first before populating `target_group_arns`.

Target groups are optional. They can be created externally, or you
can reference target groups created in another `lb_listener` module
instance.

Example usage:

```
locals {
  lb_listener_defaults = {
    environment_external_dns_zone = {
      account                = "core-vpc"
      zone_id                = data.aws_route53_zone.external-environment.zone_id
      evaluate_target_health = true
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
    development = {}
    test = {
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

module "lb_listener" {
  for_each = local.lb_listeners[local.environment]

  source = "../../modules/lb_listener"

  providers = {
    aws.core-vpc = aws.core-vpc
  }

  name              = each.key
  business_unit     = local.vpc_name
  environment       = local.environment
  load_balancer_arn = module.loadbalancer[each.value.lb_application_name].load_balancer.arn
  target_groups     = try(each.value.target_groups, {})
  port              = each.value.port
  protocol          = each.value.protocol
  ssl_policy        = try(each.value.ssl_policy, null)
  certificate_arns  = try(each.value.certificate_arns, [])
  default_action    = each.value.default_action
  rules             = try(each.value.rules, {})
  route53_records   = try(each.value.route53_records, {})
  tags              = try(each.value.tags, local.tags)
}
```
