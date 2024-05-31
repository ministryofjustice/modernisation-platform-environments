resource "aws_cloudwatch_metric_alarm" "bounce_rate_over_threshold" {
  alarm_name          = "jitbit-rds-bounce-rate-threshold"
  alarm_description   = "Triggers alarm if RDS bounce rate crosses a threshold"
  namespace           = "AWS/RDS"
  metric_name         = "BounceRate"
  statistic           = "Average"
  period              = "60"
  evaluation_periods  = "5"
  alarm_actions       = [aws_sns_topic.jitbit_alerting.arn]
  ok_actions          = [aws_sns_topic.jitbit_alerting.arn]
  threshold           = "5"
  treat_missing_data  = "missing"
  comparison_operator = "GreaterThanThreshold"

  dimensions = {
    DBInstanceIdentifier = "${local.application_name}-${local.environment}-database"
  }

  tags = merge(
    local.tags,
    {
      Name = local.application_name
    }
  )
}
