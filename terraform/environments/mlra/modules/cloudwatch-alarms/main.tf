resource "aws_cloudwatch_metric_alarm" "foobar" {
  alarm_name                = var.alarmname.value
  comparison_operator       = var.oper.value
  evaluation_periods        = var.eval.value
  metric_name               = var.metricname.value
  namespace                 = var.namespace.value
  period                    = var.period.value
  statistic                 = var.stat.value
  threshold                 = var.thresh.value
  alarm_description         = var.alarmdesc.value
  insufficient_data_actions = []
}