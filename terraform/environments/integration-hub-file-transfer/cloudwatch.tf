module "cloudwatch_eventbridge" {
  #checkov:skip=CKV_TF_1:Module registry does not support commit hashes for versions
  source  = "terraform-aws-modules/cloudwatch/aws//modules/log-group"
  version = "5.7.2"

  name              = "/aws/vendedlogs/events/event-bus/${local.application_name}"
  kms_key_id        = module.kms_cloudwatch_logs.key_arn
  retention_in_days = local.cloudwatch_retention_days

  tags = local.tags
}

module "cloudwatch_metric_alarms" {
  #checkov:skip=CKV_TF_1:Module registry does not support commit hashes for versions
  for_each = local.cloudwatch_metric_alarms

  source  = "terraform-aws-modules/cloudwatch/aws//modules/metric-alarm"
  version = "5.7.2"

  alarm_name          = "${local.application_name}-${local.environment}-${each.key}"
  alarm_description   = each.value.alarm_description
  comparison_operator = each.value.comparison_operator
  datapoints_to_alarm = try(each.value.datapoints_to_alarm, null)
  dimensions          = each.value.dimensions
  evaluation_periods  = each.value.evaluation_periods
  metric_name         = each.value.metric_name
  namespace           = each.value.namespace
  period              = each.value.period
  statistic           = each.value.statistic
  threshold           = each.value.threshold
  treat_missing_data  = "notBreaching"

  tags = local.tags
}
