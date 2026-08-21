moved {
  from = aws_cloudwatch_log_group.app_logs
  to   = aws_cloudwatch_log_group.app_logs[0]
}

moved {
  from = aws_cloudwatch_log_metric_filter.error
  to   = aws_cloudwatch_log_metric_filter.error[0]
}

moved {
  from = aws_cloudwatch_metric_alarm.jitbit_high_error_volume
  to   = aws_cloudwatch_metric_alarm.jitbit_high_error_volume[0]
}

locals {
  service_name = "hmpps-${local.environment}-${local.application_name}"
}

resource "aws_cloudwatch_log_group" "app_logs" {
  #checkov:skip=CKV_AWS_338: "Logs required for 30 days"
  count = local.create_blue_green ? 0 : 1

  name              = "delius-jitbit-ecs"
  retention_in_days = 30
  kms_key_id        = aws_kms_key.cloudwatch_logs.arn

  tags = local.tags
}

// log metric filter for error logs in container that contain the phrase "Error in Helpdesk"
resource "aws_cloudwatch_log_metric_filter" "error" {
  count = local.create_blue_green ? 0 : 1

  name           = "jitbit-application-error"
  pattern        = "Error in Helpdesk"
  log_group_name = aws_cloudwatch_log_group.app_logs[0].name

  metric_transformation {
    name          = "ErrorCount"
    namespace     = "JitbitMetrics"
    value         = "1"
    default_value = "0"
  }
}

resource "aws_cloudwatch_log_group" "app_logs_blue" {
  #checkov:skip=CKV_AWS_338: "Logs required for 30 days"
  count = local.create_blue_green ? 1 : 0

  name              = "delius-jitbit-blue-ecs"
  retention_in_days = 30
  kms_key_id        = aws_kms_key.cloudwatch_logs.arn

  tags = local.tags
}

resource "aws_cloudwatch_log_group" "app_logs_green" {
  #checkov:skip=CKV_AWS_338: "Logs required for 30 days"
  count = local.create_blue_green ? 1 : 0

  name              = "delius-jitbit-green-ecs"
  retention_in_days = 30
  kms_key_id        = aws_kms_key.cloudwatch_logs.arn

  tags = local.tags
}

# Log metric filter for blue error logs
resource "aws_cloudwatch_log_metric_filter" "error_blue" {
  count = local.create_blue_green ? 1 : 0

  name           = "jitbit-application-error-blue"
  pattern        = "Error in Helpdesk"
  log_group_name = aws_cloudwatch_log_group.app_logs_blue[0].name

  metric_transformation {
    name          = "ErrorCountBlue"
    namespace     = "JitbitMetrics"
    value         = "1"
  }
}

# Log metric filter for green error logs
resource "aws_cloudwatch_log_metric_filter" "error_green" {
  count = local.create_blue_green ? 1 : 0

  name           = "jitbit-application-error-green"
  pattern        = "Error in Helpdesk"
  log_group_name = aws_cloudwatch_log_group.app_logs_green[0].name

  metric_transformation {
    name          = "ErrorCountGreen"
    namespace     = "JitbitMetrics"
    value         = "1"
  }
}

resource "aws_cloudwatch_metric_alarm" "jitbit_high_error_volume" {
  count = local.create_blue_green ? 0 : 1

  alarm_name          = "jitbit-high-error-count"
  alarm_description   = "Triggers alarm if there are more than 10 errors for 2 consecutive periods"
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

resource "aws_cloudwatch_metric_alarm" "jitbit_high_error_volume_blue" {
  count = local.create_blue_green ? 1 : 0

  alarm_name          = "jitbit-high-error-count-blue"
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
}

resource "aws_cloudwatch_metric_alarm" "jitbit_high_error_volume_green" {
  count = local.create_blue_green ? 1 : 0

  alarm_name          = "jitbit-high-error-count-green"
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
}