locals {
  service_name = "hmpps-${local.environment}-${local.application_name}"
}

resource "aws_cloudwatch_log_group" "app_logs_blue" {
  #checkov:skip=CKV_AWS_338: "Logs required for 30 days"
  name              = "delius-jitbit-ecs-blue"
  retention_in_days = 30
  kms_key_id        = aws_kms_key.cloudwatch_logs.arn

  tags = local.tags
}

resource "aws_cloudwatch_log_group" "app_logs_green" {
  #checkov:skip=CKV_AWS_338: "Logs required for 30 days"
  name              = "delius-jitbit-ecs-green"
  retention_in_days = 30
  kms_key_id        = aws_kms_key.cloudwatch_logs.arn

  tags = local.tags
}

# Log metric filter for blue error logs
resource "aws_cloudwatch_log_metric_filter" "error_blue" {
  name           = "jitbit-application-error-blue"
  pattern        = "Error in Helpdesk"
  log_group_name = aws_cloudwatch_log_group.app_logs_blue.name

  metric_transformation {
    name      = "ErrorCountBlue"
    namespace = "JitbitMetrics"
    value     = "1"
  }
}

# Log metric filter for green error logs
resource "aws_cloudwatch_log_metric_filter" "error_green" {
  name           = "jitbit-application-error-green"
  pattern        = "Error in Helpdesk"
  log_group_name = aws_cloudwatch_log_group.app_logs_green.name

  metric_transformation {
    name      = "ErrorCountGreen"
    namespace = "JitbitMetrics"
    value     = "1"
  }
}

resource "aws_cloudwatch_metric_alarm" "jitbit_high_error_volume_blue" {
  alarm_name          = "${local.environment}-jitbit-high-error-count-blue"
  alarm_description   = "Triggers alarm if there are more than 10 errors for 2 consecutive periods"
  namespace           = "JitbitMetrics"
  metric_name         = "ErrorCountBlue"
  statistic           = "Sum"
  period              = "300"
  evaluation_periods  = "2" # number of periods over which CloudWatch evaluates the metric data
  alarm_actions       = [aws_sns_topic.jitbit_alerting.arn]
  ok_actions          = [aws_sns_topic.jitbit_alerting.arn]
  threshold           = "10"
  treat_missing_data  = "missing"
  comparison_operator = "GreaterThanThreshold"

  tags = merge(local.tags, { Name = local.application_name })
}

resource "aws_cloudwatch_metric_alarm" "jitbit_high_error_volume_green" {
  alarm_name          = "${local.environment}-jitbit-high-error-count-green"
  alarm_description   = "Triggers alarm if there are more than 10 errors for 2 consecutive periods"
  namespace           = "JitbitMetrics"
  metric_name         = "ErrorCountGreen"
  statistic           = "Sum"
  period              = "300"
  evaluation_periods  = "2" # number of periods over which CloudWatch evaluates the metric data
  alarm_actions       = [aws_sns_topic.jitbit_alerting.arn]
  ok_actions          = [aws_sns_topic.jitbit_alerting.arn]
  threshold           = "10"
  treat_missing_data  = "missing"
  comparison_operator = "GreaterThanThreshold"

  tags = merge(local.tags, { Name = local.application_name })
}