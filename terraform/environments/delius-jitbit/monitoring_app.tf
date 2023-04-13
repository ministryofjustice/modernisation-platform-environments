resource "aws_cloudwatch_log_group" "app_logs" {
  name              = "delius-jitbit-app"
  retention_in_days = 30

  tags = local.tags
}

// log metric filter for error logs in container that contain the word error or exception
resource "aws_cloudwatch_log_metric_filter" "error" {
  name           = "jitbit-application-error"
  pattern        = "Error in Helpdesk"
  log_group_name = aws_cloudwatch_log_group.app_logs.name

  metric_transformation {
    name      = "ErrorCount"
    namespace = "JitbitMetrics"
    value     = "1"
  }
}

resource "aws_cloudwatch_metric_alarm" "jitbit_high_error_volume" {
  alarm_name          = "jitbit-high-error-count"
  alarm_description   = "Triggers alarm if there are more than 5 errors in the last 5 minutes"
  namespace           = "JitbitMetrics"
  metric_name         = "ErrorCount"
  statistic           = "Sum"
  period              = "300"
  evaluation_periods  = "1"
  alarm_actions       = [aws_sns_topic.jitbit_alerting.arn]
  ok_actions          = [aws_sns_topic.jitbit_alerting.arn]
  threshold           = "5"
  treat_missing_data  = "missing"
  comparison_operator = "GreaterThanThreshold"
}
