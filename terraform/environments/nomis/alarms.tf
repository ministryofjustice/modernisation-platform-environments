resource "aws_cloudwatch_metric_alarm" "cpu_utilization" {
  alarm_name          = "cpu_utilization"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = "2"
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = "60"
  statistic           = "Average"
  threshold           = "80"
  alarm_description   = "This metric monitors ec2 cpu utilization"
  # alarm_actions       = [aws_sns_topic.alarm.arn] TODO: needs changing - need our own SNS topic using our own pagerduty-integration module
  # dimensions = {
  #   InstanceId = aws_instance.example.id TODO: change this so it works on a per-instance basis
  #}
  tags = {
    Name = "cpu_utilization"
  }
}
