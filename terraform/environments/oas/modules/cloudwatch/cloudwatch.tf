resource "aws_cloudwatch_metric_alarm" "alarm" {
  for_each = var.cloudwatch_metric_alarms

  alarm_name          = each.value.alarm_name
  alarm_description   = each.value.alarm_description
  comparison_operator = each.value.comparison_operator
  dimensions          = each.value.dimensions
  evaluation_periods  = each.value.evaluation_periods
  metric_name         = each.value.metric_name
  namespace           = each.value.namespace
  period              = each.value.period
  statistic           = each.value.statistic
  threshold           = each.value.threshold
  alarm_actions       = [aws_sns_topic.alerting_topic.arn]
  ok_actions          = [aws_sns_topic.alerting_topic.arn]
  treat_missing_data  = each.value.treat_missing_data
}

data "template_file" "dashboard" {
  template = file("${path.module}/dashboard.tpl")

  vars = {
    dashboard_widget_refresh_period = var.dashboard_widget_refresh_period
    aws_region                      = var.aws_region
    cpu_alarm_arn                   = aws_cloudwatch_metric_alarm.alarm["ec2_cpu_utilisation_too_high"].arn
    memory_alarm_arn                = aws_cloudwatch_metric_alarm.alarm["ec2_memory_over_threshold"].arn
    ebs_volume_alarm_arn            = aws_cloudwatch_metric_alarm.alarm["ebs_software_disk_space_used_over_threshold"].arn
    ebs_root_volume_alarm_arn       = aws_cloudwatch_metric_alarm.alarm["ebs_root_disk_space_used_over_threshold"].arn
  }
}

resource "aws_cloudwatch_dashboard" "dashboard" {
  dashboard_name = var.dashboard_name
  dashboard_body = data.template_file.dashboard.rendered
}

# SNS topic for monitoring to send alarms to
resource "aws_sns_topic" "alerting_topic" {
  name = var.snsTopicName
}
