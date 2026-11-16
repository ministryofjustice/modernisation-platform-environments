resource "aws_cloudwatch_log_group" "flink_log_group" {
  name              = "/aws/kinesis-analytics/${lower(var.config_property_group.app_name)}-flink-streaming-application"
  retention_in_days = var.config_property_group.log_retention_days
  kms_key_id        = var.cloudwatch_kms_key_arn
  tags              = var.tags
}

resource "aws_cloudwatch_log_stream" "flink_log_stream" {
  name           = "${lower(var.config_property_group.app_name)}-log-group"
  log_group_name = aws_cloudwatch_log_group.flink_log_group.name
}
resource "aws_cloudwatch_metric_alarm" "application_failed" {
  count = var.enable_cloudwatch_alarms ? 1 : 0

  alarm_name          = "${lower(var.config_property_group.app_name)}-application-failed"
  alarm_description   = "Alerts when the Flink application fails."
  namespace           = "AWS/KinesisAnalytics"
  metric_name         = "ApplicationFailed"
  statistic           = "Maximum"
  period              = var.application_failed_period
  evaluation_periods  = 1
  threshold           = var.application_failed_threshold
  comparison_operator = "GreaterThanThreshold"
  treat_missing_data  = "notBreaching"
  alarm_actions       = var.alarm_actions
  ok_actions          = var.ok_actions
  tags                = var.tags

  dimensions = {
    Application = lower(var.config_property_group.app_name)
  }
}

resource "aws_cloudwatch_metric_alarm" "full_restarts" {
  count = var.enable_cloudwatch_alarms ? 1 : 0

  alarm_name          = "${lower(var.config_property_group.app_name)}-full-restarts"
  alarm_description   = "Alerts when the Flink application restarts repeatedly."
  namespace           = "AWS/KinesisAnalytics"
  metric_name         = "fullRestarts"
  statistic           = "Sum"
  period              = var.full_restarts_period
  evaluation_periods  = 1
  threshold           = var.full_restarts_threshold
  comparison_operator = "GreaterThanThreshold"
  treat_missing_data  = "notBreaching"
  alarm_actions       = var.alarm_actions
  ok_actions          = var.ok_actions
  tags                = var.tags

  dimensions = {
    Application = lower(var.config_property_group.app_name)
  }
}
