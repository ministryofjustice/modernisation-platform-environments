resource aws_cloudwatch_log_group app_logs {
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
