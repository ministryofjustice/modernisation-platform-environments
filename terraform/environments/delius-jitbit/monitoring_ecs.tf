# Terraform alarms for ECS Cluster
locals {
  cluster_name = split("/", module.ecs.ecs_cluster_arn)[1]
}
# Alarm for high CPU usage
resource "aws_cloudwatch_metric_alarm" "jitbit_cpu_over_threshold" {
  alarm_name          = "jitbit-ecs-cpu-threshold"
  alarm_description   = "Triggers alarm if ECS CPU crosses a threshold"
  namespace           = "ECS/ContainerInsights"
  metric_name         = "CpuUtilized"
  statistic           = "Average"
  period              = "60"
  evaluation_periods  = "5"
  alarm_actions       = [aws_sns_topic.jitbit_alerting.arn]
  ok_actions          = [aws_sns_topic.jitbit_alerting.arn]
  threshold           = "10"
  treat_missing_data  = "missing"
  comparison_operator = "GreaterThanThreshold"

  dimensions = {
    ClusterName = local.cluster_name
  }
}

# Alarm for high memory usage
resource "aws_cloudwatch_metric_alarm" "jitbit_memory_over_threshold" {
  alarm_name          = "jitbit-ecs-memory-threshold"
  alarm_description   = "Triggers alarm if ECS memory crosses a threshold"
  namespace           = "ECS/ContainerInsights"
  metric_name         = "MemoryUtilized"
  statistic           = "Average"
  period              = "60"
  evaluation_periods  = "5"
  alarm_actions       = [aws_sns_topic.jitbit_alerting.arn]
  ok_actions          = [aws_sns_topic.jitbit_alerting.arn]
  threshold           = "600"
  treat_missing_data  = "missing"
  comparison_operator = "GreaterThanThreshold"

  dimensions = {
    ClusterName = local.cluster_name
  }
}
