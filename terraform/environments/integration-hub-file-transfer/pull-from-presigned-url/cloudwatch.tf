module "cloudwatch_metric_alarms" {
  #checkov:skip=CKV_TF_1:Module registry does not support commit hashes for versions
  for_each = local.cloudwatch_metric_alarms

  source  = "terraform-aws-modules/cloudwatch/aws//modules/metric-alarm"
  version = "5.7.3"

  alarm_name          = "${local.pattern_name}-${each.key}"
  alarm_description   = each.value.alarm_description
  comparison_operator = each.value.comparison_operator
  dimensions          = each.value.dimensions
  datapoints_to_alarm = try(each.value.datapoints_to_alarm, null)
  evaluation_periods  = each.value.evaluation_periods
  metric_name         = each.value.metric_name
  namespace           = each.value.namespace
  period              = each.value.period
  statistic           = each.value.statistic
  threshold           = each.value.threshold
  treat_missing_data  = "notBreaching"
  alarm_actions       = local.cloudwatch_alarm_actions[each.key]
  ok_actions          = local.cloudwatch_alarm_actions[each.key]

  tags = local.tags
}

resource "aws_cloudwatch_log_metric_filter" "record_failures" {
  name           = "${local.pattern_name}-record-failures"
  log_group_name = module.lambda_notifier.lambda_cloudwatch_log_group_name
  pattern        = "{ $.outcome = \"failed\" }"
  metric_transformation {
    name      = "RecordFailures"
    namespace = "IntegrationHub/SlackPickup"
    value     = "1"
  }
}
