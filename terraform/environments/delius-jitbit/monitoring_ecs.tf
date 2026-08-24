moved {
  from = aws_cloudwatch_metric_alarm.jitbit_memory_over_threshold
  to   = aws_cloudwatch_metric_alarm.jitbit_memory_over_threshold[0]
}

moved {
  from = aws_cloudwatch_metric_alarm.jitbit_cpu_over_threshold
  to   = aws_cloudwatch_metric_alarm.jitbit_cpu_over_threshold[0]
}

# Terraform alarms for ECS Cluster
locals {
  cluster_name = split("/", module.ecs.ecs_cluster_arn)[1]
}

# Alarm for high CPU usage
resource "aws_cloudwatch_metric_alarm" "jitbit_cpu_over_threshold" {
  count = local.create_blue_green ? 0 : 1

  alarm_name          = "jitbit-ecs-cpu-threshold"
  alarm_description   = "Triggers alarm if ECS CPU crosses a threshold"
  namespace           = "AWS/ECS"
  metric_name         = "CPUUtilization"
  statistic           = "Average"
  period              = "60"
  evaluation_periods  = "5"
  alarm_actions       = [aws_sns_topic.jitbit_alerting.arn]
  ok_actions          = [aws_sns_topic.jitbit_alerting.arn]
  threshold           = "80"
  treat_missing_data  = "missing"
  comparison_operator = "GreaterThanThreshold"

  dimensions = {
    ClusterName = local.cluster_name
    ServiceName = local.cluster_name
  }

  tags = merge(
    local.tags,
    {
      Name = local.application_name
    }
  )
}

# Alarm for high memory usage
resource "aws_cloudwatch_metric_alarm" "jitbit_memory_over_threshold" {
  count = local.create_blue_green ? 0 : 1

  alarm_name          = "jitbit-ecs-memory-threshold"
  alarm_description   = "Triggers alarm if ECS memory crosses a threshold"
  namespace           = "AWS/ECS"
  metric_name         = "MemoryUtilization"
  statistic           = "Average"
  period              = "60"
  evaluation_periods  = "5"
  alarm_actions       = [aws_sns_topic.jitbit_alerting.arn]
  ok_actions          = [aws_sns_topic.jitbit_alerting.arn]
  threshold           = "80"
  treat_missing_data  = "missing"
  comparison_operator = "GreaterThanThreshold"

  dimensions = {
    ClusterName = local.cluster_name
    ServiceName = local.cluster_name
  }

  tags = merge(
    local.tags,
    {
      Name = local.application_name
    }
  )
}

# Alarm for high CPU usage
resource "aws_cloudwatch_metric_alarm" "jitbit_cpu_over_threshold_blue" {
  count = local.create_blue_green ? 1 : 0

  alarm_name          = "jitbit-ecs-cpu-threshold-blue"
  alarm_description   = "Triggers alarm if ECS CPU crosses a threshold"
  namespace           = "AWS/ECS"
  metric_name         = "CPUUtilization"
  statistic           = "Average"
  period              = "60"
  evaluation_periods  = "5"
  alarm_actions       = [aws_sns_topic.jitbit_alerting.arn]
  ok_actions          = [aws_sns_topic.jitbit_alerting.arn]
  threshold           = "80"
  treat_missing_data  = "missing"
  comparison_operator = "GreaterThanThreshold"

  dimensions = {
    ClusterName = local.cluster_name
    ServiceName = "${local.cluster_name}-blue"
  }

  tags = merge(
    local.tags,
    {
      Name = "${local.application_name}-blue"
    }
  )
}

# Alarm for high CPU usage
resource "aws_cloudwatch_metric_alarm" "jitbit_cpu_over_threshold_green" {
  count = local.create_blue_green ? 1 : 0

  alarm_name          = "jitbit-ecs-cpu-threshold-green"
  alarm_description   = "Triggers alarm if ECS CPU crosses a threshold"
  namespace           = "AWS/ECS"
  metric_name         = "CPUUtilization"
  statistic           = "Average"
  period              = "60"
  evaluation_periods  = "5"
  alarm_actions       = [aws_sns_topic.jitbit_alerting.arn]
  ok_actions          = [aws_sns_topic.jitbit_alerting.arn]
  threshold           = "80"
  treat_missing_data  = "missing"
  comparison_operator = "GreaterThanThreshold"

  dimensions = {
    ClusterName = local.cluster_name
    ServiceName = "${local.cluster_name}-green"
  }

  tags = merge(
    local.tags,
    {
      Name = "${local.application_name}-green"
    }
  )
}

# Alarm for high memory usage
resource "aws_cloudwatch_metric_alarm" "jitbit_memory_over_threshold_blue" {
  count = local.create_blue_green ? 1 : 0

  alarm_name          = "jitbit-ecs-memory-threshold-blue"
  alarm_description   = "Triggers alarm if ECS memory crosses a threshold"
  namespace           = "AWS/ECS"
  metric_name         = "MemoryUtilization"
  statistic           = "Average"
  period              = "60"
  evaluation_periods  = "5"
  alarm_actions       = [aws_sns_topic.jitbit_alerting.arn]
  ok_actions          = [aws_sns_topic.jitbit_alerting.arn]
  threshold           = "80"
  treat_missing_data  = "missing"
  comparison_operator = "GreaterThanThreshold"

  dimensions = {
    ClusterName = local.cluster_name
    ServiceName = "${local.cluster_name}-blue"
  }

  tags = merge(
    local.tags,
    {
      Name = "${local.application_name}-blue"
    }
  )
}

# Alarm for high memory usage
resource "aws_cloudwatch_metric_alarm" "jitbit_memory_over_threshold_green" {
  count = local.create_blue_green ? 1 : 0

  alarm_name          = "jitbit-ecs-memory-threshold-green"
  alarm_description   = "Triggers alarm if ECS memory crosses a threshold"
  namespace           = "AWS/ECS"
  metric_name         = "MemoryUtilization"
  statistic           = "Average"
  period              = "60"
  evaluation_periods  = "5"
  alarm_actions       = [aws_sns_topic.jitbit_alerting.arn]
  ok_actions          = [aws_sns_topic.jitbit_alerting.arn]
  threshold           = "80"
  treat_missing_data  = "missing"
  comparison_operator = "GreaterThanThreshold"

  dimensions = {
    ClusterName = local.cluster_name
    ServiceName = "${local.cluster_name}-green"
  }

  tags = merge(
    local.tags,
    {
      Name = "${local.application_name}-green"
    }
  )
}