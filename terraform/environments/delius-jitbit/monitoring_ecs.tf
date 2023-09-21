# Terraform alarms for ECS Cluster
locals {
  cluster_name = split("/", module.ecs.ecs_cluster_arn)[1]
}
# Alarm for high CPU usage
resource "aws_cloudwatch_metric_alarm" "jitbit_cpu_over_threshold" {
  alarm_name                = "jitbit-ecs-cpu-threshold"
  comparison_operator       = "GreaterThanUpperThreshold"
  evaluation_periods        = "5"
  threshold_metric_id       = "e1"
  alarm_description         = "Triggers alarm if ECS CPU crosses a threshold"
  insufficient_data_actions = []
  alarm_actions             = [aws_sns_topic.jitbit_alerting.arn]
  ok_actions                = [aws_sns_topic.jitbit_alerting.arn]
  treat_missing_data        = "missing"

  metric_query {
    id          = "e1"
    expression  = "ANOMALY_DETECTION_BAND(m1)"
    label       = "CpuUtilized (Expected)"
    return_data = "true"
  }

  metric_query {
    id          = "m1"
    return_data = "true"
    metric {
      metric_name = "CpuUtilized"
      namespace   = "ECS/ContainerInsights"
      period      = "60"
      stat        = "Average"
      unit        = "Count"

      dimensions = {
        ClusterName = local.cluster_name
      }
    }
  }
}

# Alarm for high memory usage
resource "aws_cloudwatch_metric_alarm" "jitbit_memory_over_threshold" {
  alarm_name                = "jitbit-ecs-memory-threshold"
  comparison_operator       = "GreaterThanUpperThreshold"
  evaluation_periods        = "5"
  threshold_metric_id       = "e1"
  alarm_description         = "Triggers alarm if ECS memory crosses a threshold"
  insufficient_data_actions = []
  alarm_actions             = [aws_sns_topic.jitbit_alerting.arn]
  ok_actions                = [aws_sns_topic.jitbit_alerting.arn]
  treat_missing_data        = "missing"

  metric_query {
    id          = "e1"
    expression  = "ANOMALY_DETECTION_BAND(m1)"
    label       = "MemoryUtilized (Expected)"
    return_data = "true"
  }

  metric_query {
    id          = "m1"
    return_data = "true"
    metric {
      metric_name = "MemoryUtilized"
      namespace   = "ECS/ContainerInsights"
      period      = "60"
      stat        = "Average"
      unit        = "Count"

      dimensions = {
        ClusterName = local.cluster_name
      }
    }
  }
}
