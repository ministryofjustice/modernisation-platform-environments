resource "aws_cloudwatch_metric_alarm" "bounce_rate_over_warning_threshold" {
  alarm_name          = "jitbit-rds-bounce-rate-threshold"
  alarm_description   = "Triggers alarm if SES bounce rate crosses a threshold"
  namespace           = "AWS/SES"
  metric_name         = "Reputation.BounceRate"
  statistic           = "Average"
  period              = "60"
  evaluation_periods  = "5"
  alarm_actions       = [aws_sns_topic.jitbit_alerting.arn]
  ok_actions          = [aws_sns_topic.jitbit_alerting.arn]
  threshold           = "0.025"
  treat_missing_data  = "missing"
  comparison_operator = "GreaterThanThreshold"

  tags = merge(
    local.tags,
    {
      Name = local.application_name
    }
  )
}

resource "aws_cloudwatch_metric_alarm" "bounce_rate_over_critical_threshold" {
  alarm_name          = "jitbit-rds-bounce-rate-critical-threshold"
  alarm_description   = "Triggers alarm if SES bounce rate crosses a critical threshold"
  namespace           = "AWS/SES"
  metric_name         = "Reputation.BounceRate"
  statistic           = "Average"
  period              = "60"
  evaluation_periods  = "5"
  alarm_actions       = [aws_sns_topic.jitbit_alerting.arn]
  ok_actions          = [aws_sns_topic.jitbit_alerting.arn]
  threshold           = "0.05"
  treat_missing_data  = "missing"
  comparison_operator = "GreaterThanThreshold"

  tags = merge(
    local.tags,
    {
      Name = local.application_name
    }
  )
}
