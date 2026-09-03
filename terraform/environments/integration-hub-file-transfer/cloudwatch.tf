module "cloudwatch_eventbridge" {
  #checkov:skip=CKV_TF_1:Module registry does not support commit hashes for versions
  source  = "terraform-aws-modules/cloudwatch/aws//modules/log-group"
  version = "5.7.2"

  name              = "/aws/vendedlogs/events/event-bus/${local.application_name}"
  kms_key_id        = module.kms_cloudwatch_logs.key_arn
  retention_in_days = local.cloudwatch_retention_days

  tags = local.tags
}

module "cloudwatch_log_metric_filters" {
  #checkov:skip=CKV_TF_1:Module registry does not support commit hashes for versions
  for_each = local.cloudwatch_log_metric_filters

  source  = "terraform-aws-modules/cloudwatch/aws//modules/log-metric-filter"
  version = "5.7.2"

  log_group_name                  = each.value.log_group_name
  metric_transformation_name      = each.value.metric_transformation_name
  metric_transformation_namespace = each.value.metric_transformation_namespace
  name                            = "${local.application_name}-${local.environment}-${each.key}"
  pattern                         = each.value.pattern
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
  alarm_actions       = local.cloudwatch_alarm_actions[each.key]

  tags = local.tags
}

module "cloudwatch_transfer" {
  #checkov:skip=CKV_TF_1:Module registry does not support commit hashes for versions
  source  = "terraform-aws-modules/cloudwatch/aws//modules/log-group"
  version = "5.7.2"

  name              = "/aws/transfer/${local.application_name}"
  kms_key_id        = module.kms_cloudwatch_logs.key_arn
  retention_in_days = local.cloudwatch_retention_days

  tags = local.tags
}
