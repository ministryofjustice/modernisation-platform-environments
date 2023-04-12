resource "aws_lb_listener" "this" {
  load_balancer_arn = local.aws_lb.arn
  port              = var.port
  protocol          = var.protocol
  ssl_policy        = var.ssl_policy
  certificate_arn   = length(var.certificate_names_or_arns) != 0 ? lookup(var.certificate_arn_lookup, var.certificate_names_or_arns[0], var.certificate_names_or_arns[0]) : null

  dynamic "default_action" {
    for_each = [var.default_action]

    content {
      type             = default_action.value.type
      target_group_arn = default_action.value.target_group_name != null ? local.target_groups[default_action.value.target_group_name].arn : default_action.value.target_group_arn

      dynamic "fixed_response" {
        for_each = default_action.value.fixed_response != null ? [default_action.value.fixed_response] : []
        content {
          content_type = fixed_response.value.content_type
          message_body = fixed_response.value.message_body
          status_code  = fixed_response.value.status_code
        }
      }

      dynamic "forward" {
        for_each = default_action.value.forward != null ? [default_action.value.forward] : []
        content {
          dynamic "target_group" {
            for_each = forward.value.target_group
            content {
              arn    = target_group.value.name != null ? local.target_groups[target_group.value.name].arn : target_group.value.arn
              weight = target_group.value.weight
            }
          }
          dynamic "stickiness" {
            for_each = forward.value.stickiness != null ? [forward.value.stickiness] : []
            content {
              duration = stickiness.value.duration
              enabled  = stickiness.value.enabled
            }
          }
        }
      }

      dynamic "redirect" {
        for_each = default_action.value.redirect != null ? [default_action.value.redirect] : []
        content {
          status_code = redirect.value.status_code
          port        = redirect.value.port
          protocol    = redirect.value.protocol
        }
      }
    }
  }

  tags = merge(var.tags, {
    Name = var.name
  })
}

resource "aws_lb_listener_rule" "this" {
  for_each = var.rules

  listener_arn = aws_lb_listener.this.arn
  priority     = each.value.priority

  dynamic "action" {
    for_each = each.value.actions

    content {
      type             = action.value.type
      target_group_arn = action.value.target_group_name != null ? local.target_groups[action.value.target_group_name].arn : action.value.target_group_arn

      dynamic "fixed_response" {
        for_each = action.value.fixed_response != null ? [action.value.fixed_response] : []
        content {
          content_type = fixed_response.value.content_type
          message_body = fixed_response.value.message_body
          status_code  = fixed_response.value.status_code
        }
      }

      dynamic "forward" {
        for_each = action.value.forward != null ? [action.value.forward] : []
        content {
          dynamic "target_group" {
            for_each = forward.value.target_group
            content {
              arn    = target_group.value.name != null ? local.target_groups[target_group.value.name].arn : target_value.value.arn
              weight = target_group.value.weight
            }
          }
          dynamic "stickiness" {
            for_each = forward.value.stickiness != null ? [forward.value.stickiness] : []
            content {
              duration = stickiness.value.duration
              enabled  = stickiness.value.enabled
            }
          }
        }
      }

      dynamic "redirect" {
        for_each = action.value.redirect != null ? [action.value.redirect] : []
        content {
          status_code = redirect.value.status_code
          port        = redirect.value.port
          protocol    = redirect.value.protocol
        }
      }
    }
  }

  dynamic "condition" {
    for_each = each.value.conditions
    content {
      dynamic "host_header" {
        for_each = condition.value.host_header != null ? [condition.value.host_header] : []
        content {
          values = host_header.value.values
        }
      }
      dynamic "path_pattern" {
        for_each = condition.value.path_pattern != null ? [condition.value.path_pattern] : []
        content {
          values = path_pattern.value.values
        }
      }
    }
  }

  tags = merge(var.tags, {
    Name = "${var.name}-${each.key}"
  })
}

resource "aws_lb_listener_certificate" "this" {
  for_each        = toset(var.certificate_names_or_arns)
  listener_arn    = aws_lb_listener.this.arn
  certificate_arn = lookup(var.certificate_arn_lookup, each.value, each.value)
}

resource "aws_cloudwatch_metric_alarm" "this" {
  for_each = local.cloudwatch_metric_alarms

  alarm_name          = "${var.name}-${each.key}"
  comparison_operator = each.value.comparison_operator
  evaluation_periods  = each.value.evaluation_periods
  metric_name         = each.value.metric_name
  namespace           = each.value.namespace
  period              = each.value.period
  statistic           = each.value.statistic
  threshold           = each.value.threshold
  alarm_actions       = each.value.alarm_actions
  alarm_description   = each.value.alarm_description
  datapoints_to_alarm = each.value.datapoints_to_alarm
  treat_missing_data  = each.value.treat_missing_data
  dimensions = merge(each.value.dimensions, {
    "LoadBalancer" = local.aws_lb.arn_suffix
    "TargetGroup"  = each.value.target_group_arn_suffix
  })
  tags = merge(var.tags, {
    Name = "${var.name}-${each.key}"
  })
}
