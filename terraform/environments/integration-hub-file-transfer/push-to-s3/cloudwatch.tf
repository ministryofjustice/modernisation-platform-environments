module "cloudwatch_metric_alarms" {
  #checkov:skip=CKV_TF_1:Module registry does not support commit hashes for versions
  for_each = local.cloudwatch_metric_alarms

  source  = "terraform-aws-modules/cloudwatch/aws//modules/metric-alarm"
  version = "5.7.3"

  alarm_name          = "${local.pattern_name}-${each.key}"
  alarm_description   = each.value.alarm_description
  comparison_operator = each.value.comparison_operator
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