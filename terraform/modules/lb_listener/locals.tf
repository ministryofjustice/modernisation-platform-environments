locals {
  aws_lb = var.load_balancer_arn != null ? data.aws_lb.this[0] : var.load_balancer

  target_groups = var.existing_target_groups

  cloudwatch_metric_alarms_list = flatten([
    for target_group_name in var.alarm_target_group_names : [
      for cloudwatch_metric_alarm_key, alarm_value in var.cloudwatch_metric_alarms : {
        key = "${target_group_name}-${cloudwatch_metric_alarm_key}"
        value = merge(alarm_value, {
          target_group_arn_suffix = local.target_groups[target_group_name].arn_suffix
        })
      }
    ]
  ])

  cloudwatch_metric_alarms = {
    for item in local.cloudwatch_metric_alarms_list : item.key => item.value
  }
}
