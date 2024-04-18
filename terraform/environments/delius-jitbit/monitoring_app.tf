resource "aws_cloudwatch_log_group" "app_logs" {
  name              = "delius-jitbit-ecs"
  retention_in_days = 30

  tags = local.tags
}

// log metric filter for error logs in container that contain the phrase "Error in Helpdesk"
resource "aws_cloudwatch_log_metric_filter" "error" {
  name           = "jitbit-application-error"
  pattern        = "Error in Helpdesk"
  log_group_name = aws_cloudwatch_log_group.app_logs.name

  metric_transformation {
    name          = "ErrorCount"
    namespace     = "JitbitMetrics"
    value         = "1"
    default_value = "0"
  }
}

resource "aws_cloudwatch_metric_alarm" "jitbit_high_error_volume" {
  alarm_name          = "jitbit-high-error-count"
  alarm_description   = "Triggers alarm if there are more than 10 errors for 2 consecitive periods"
  namespace           = "JitbitMetrics"
  metric_name         = "ErrorCount"
  statistic           = "Sum"
  period              = "300"
  evaluation_periods  = "2" # number of periods over which CloudWatch evaluates the metric data
  alarm_actions       = [aws_sns_topic.jitbit_alerting.arn]
  ok_actions          = [aws_sns_topic.jitbit_alerting.arn]
  threshold           = "10"
  treat_missing_data  = "missing"
  comparison_operator = "GreaterThanThreshold"
}
