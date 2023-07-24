locals {
  cloudwatch_metric_alarms_list_by_dimension_list = flatten([
    for alarm_key, alarm_value in var.cloudwatch_metric_alarms : [
      for dimension_value in alarm_value.split_by_dimension.dimension_values : [{
        key = "${alarm_key}-${dimension_value}"
        value = merge(alarm_value, {
          dimensions = merge(alarm_value.dimensions, {
            (alarm_value.split_by_dimension.dimension_name) = dimension_value
          })
        })
      }]
    ] if alarm_value.split_by_dimension != null
  ])
  cloudwatch_metric_alarms_list_by_dimension = {
    for item in local.cloudwatch_metric_alarms_list_by_dimension_list :
    item.key => item.value
  }
  cloudwatch_metric_alarms_list_without_dimension = {
    for alarm_key, alarm_value in var.cloudwatch_metric_alarms :
    alarm_key => alarm_value if alarm_value.split_by_dimension == null
  }
  cloudwatch_metric_alarms = merge(
    local.cloudwatch_metric_alarms_list_by_dimension,
    local.cloudwatch_metric_alarms_list_without_dimension
  )
}

resource "aws_cloudwatch_log_group" "this" {
  for_each = var.cloudwatch_log_groups

  name              = each.key
  retention_in_days = each.value.retention_in_days
  skip_destroy      = each.value.skip_destroy
  kms_key_id        = each.value.kms_key_id

  tags = merge(local.tags, each.value.tags, {
    Name = each.key
  })
}

resource "aws_cloudwatch_log_metric_filter" "this" {
  for_each = var.cloudwatch_log_metric_filters

  name           = each.key
  pattern        = each.value.pattern
  log_group_name = each.value.log_group_name

  metric_transformation {
    name          = each.value.metric_transformation.name
    namespace     = each.value.metric_transformation.namespace
    value         = each.value.metric_transformation.value
    default_value = each.value.metric_transformation.default_value
    dimensions    = each.value.metric_transformation.dimensions
    unit          = each.value.metric_transformation.unit
  }
}

resource "aws_cloudwatch_metric_alarm" "this" {
  for_each = local.cloudwatch_metric_alarms

  alarm_name          = each.key
  comparison_operator = each.value.comparison_operator
  evaluation_periods  = each.value.evaluation_periods
  metric_name         = each.value.metric_name
  namespace           = each.value.namespace
  period              = each.value.period
  statistic           = each.value.statistic
  threshold           = each.value.threshold

  alarm_actions = [
    for item in each.value.alarm_actions : try(aws_sns_topic.this[item].arn, item)
  ]

  alarm_description   = each.value.alarm_description
  datapoints_to_alarm = each.value.datapoints_to_alarm
  treat_missing_data  = each.value.treat_missing_data
  dimensions          = each.value.dimensions

  tags = merge(local.tags, {
    Name = each.key
  })
}
