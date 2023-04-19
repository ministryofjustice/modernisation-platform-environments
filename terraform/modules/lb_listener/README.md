Create an `aws_lb_listener` with associated resources such as:

- `aws_lb_listener_rule`
- `aws_lb_listener_certificate`

Note that only one listener is allowed for each protocol/port. Add
multiple target groups and listener rules as required.

Target groups should be created outside of this module. Either
reference the target group ARN in rules, or pass in a map of target
group resources and reference by name.

Optionally create a set of cloudwatch alarms for each target group
using `cloudwatch_metric_alarms` and `alarm_target_group_names`
variables.

Example usage:

```
locals {

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
  lb_listeners = {
    http = {
      lb_application_name = "public"
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
    https = {
      lb_application_name = "public"
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
      rules = {
        http-7777-asg = {
          actions = [{
            type              = "forward"
            target_group_name = "http-7777-asg"
          }]
          conditions = [{
            host_header = {
              values = ["*-asg.*"]
            }
          }]
        }
      }
    }
  }
}

module "lb_listener" {
  for_each = local.lb_listeners

  source = "../../modules/lb_listener"

  name              = each.key
  business_unit     = local.vpc_name
  environment       = local.environment
  load_balancer_arn = module.loadbalancer[each.value.lb_application_name].load_balancer.arn
  target_groups     = local.target_groups
  port              = each.value.port
  protocol          = each.value.protocol
  ssl_policy        = try(each.value.ssl_policy, null)
  certificate_arns  = try(each.value.certificate_arns, [])
  default_action    = each.value.default_action
  rules             = try(each.value.rules, {})
  tags              = try(each.value.tags, local.tags)
}
```
