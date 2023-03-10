resource "aws_cloudwatch_metric_alarm" "cpu_over_threshold" {
  alarm_name         = "jitbit-rds-cpu-threshold"
  alarm_description  = "Triggers alarm if RDS CPU crosses a threshold"
  namespace          = "AWS/RDS"
  metric_name        = "CPUUtilization"
  statistic          = "Average"
  period             = "60"
  evaluation_periods = "5"
  alarm_actions      = [aws_sns_topic.jitbit_alerting_topic.arn]
  ok_actions         = [aws_sns_topic.jitbit_alerting_topic.arn]
  threshold          = "80"
  treat_missing_data = "missing"
  comparison_operator = "GreaterThanThreshold"
  tags = merge(
    var.tags,
    {
      Name = "jitbit-rds-cpu-threshold"
    }
  )
}

resource "aws_cloudwatch_metric_alarm" "ram_over_threshold" {
  alarm_name         = "jitbit-rds-ram-threshold"
  alarm_description  = "Triggers alarm if RDS RAM crosses a threshold"
  namespace          = "AWS/RDS"
  metric_name        = "FreeableMemory"
  statistic          = "Average"
  period             = "60"
  evaluation_periods = "5"
  alarm_actions      = [aws_sns_topic.jitbit_alerting_topic.arn]
  ok_actions         = [aws_sns_topic.jitbit_alerting_topic.arn]
  threshold          = "2500"
  treat_missing_data = "missing"
  comparison_operator = "LessThanThreshold"
  tags = merge(
    var.tags,
    {
      Name = "jitbit-rds-ram-threshold"
    }
  )
}

resource "aws_cloudwatch_metric_alarm" "read_latency_over_threshold" {
  alarm_name         = "jitbit-rds-read-latency-threshold"
  alarm_description  = "Triggers alarm if RDS read latency crosses a threshold"
  namespace          = "AWS/RDS"
  metric_name        = "ReadLatency"
  statistic          = "Average"
  period             = "60"
  evaluation_periods = "5"
  alarm_actions      = [aws_sns_topic.jitbit_alerting_topic.arn]
  ok_actions         = [aws_sns_topic.jitbit_alerting_topic.arn]
  threshold          = "5"
  treat_missing_data = "missing"
  comparison_operator = "GreaterThanThreshold"
  tags = merge(
    var.tags,
    {
      Name = "jitbit-rds-ram-threshold"
    }
  )
}
