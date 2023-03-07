Create an `aws_lb_listener` with associated resources such as:

- `aws_lb_target_group`
- `aws_lb_target_group_attachment`
- `aws_lb_listener_rule`
- `aws_lb_listener_certificate`
- `aws_route53_record`

Note that only one listener is allowed for each protocol/port.  Add
multiple target groups and listener rules as required.

If associating with an `aws_autoscaling_group`, be sure to create the
load balancer resource first before populating `target_group_arns`.

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
  lb_dns_zone = {
    account                = "core-vpc"
    zone_id                = data.aws_route53_zone.external-environment.zone_id
    evaluate_target_health = true
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
      target_groups = {
        http-7777-asg = local.lb_http_7777_rule
        http-7777-instance = merge(local.lb_http_7777_rule, {
          attachments = [
            {
              target_id = local.my_instance_id_1
            },
            {
              target_id = local.my_instance_id_2
            }
          ]
        })
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
        http-7777-instance = {
          actions = [{
            type              = "forward"
            target_group_name = "http-7777-instance"
          }]
          conditions = [{
            host_header = {
              values = ["*-instance.*"]
            }
          }]
        }
      }
      route53_records = {
        "my-asg"      = local.lb_dns_zone
        "my-instance" = local.lb_dns_zone
      }
    }
  }
}

module "lb_listener" {
  for_each = local.lb_listeners

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

Alarms are being configured in this module. You can specify the alarm actions in the local.lb_listeners_sns_topic[local.environment] "sns_topic" value.
