# Terraform alarms for ECS Cluster
locals {
  cluster_name = split("/", var.ecs_cluster_arn)[1]
}
# Alarm for high CPU usage
resource "aws_cloudwatch_metric_alarm" "cpu_over_threshold" {
  alarm_name                = "${var.name}-ecs-cpu-threshold"
  comparison_operator       = "GreaterThanUpperThreshold"
  evaluation_periods        = "5"
  threshold_metric_id       = "e1"
  alarm_description         = "Triggers alarm if ECS CPU crosses a threshold"
  insufficient_data_actions = []
  # add sns topic later
  #  alarm_actions       = [aws_sns_topic.alerting.arn]
  #  ok_actions          = [aws_sns_topic.alerting.arn]
  treat_missing_data = "missing"

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
resource "aws_cloudwatch_metric_alarm" "memory_over_threshold" {
  alarm_name                = "${var.name}-ecs-memory-threshold"
  comparison_operator       = "GreaterThanUpperThreshold"
  evaluation_periods        = "5"
  threshold_metric_id       = "e1"
  alarm_description         = "Triggers alarm if ECS memory crosses a threshold"
  insufficient_data_actions = []
  # add sns topic later
  #  alarm_actions       = [aws_sns_topic.alerting.arn]
  #  ok_actions          = [aws_sns_topic.alerting.arn]
  treat_missing_data = "missing"

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


// log metric filter for error logs in container that contain the phrase "Error in Helpdesk"
resource "aws_cloudwatch_log_metric_filter" "error" {
  name           = "${var.name}-application-error"
  pattern        = "Error in Helpdesk"
  log_group_name = aws_cloudwatch_log_group.ecs.name

  metric_transformation {
    name          = "ErrorCount"
    namespace     = "${var.name}Metrics"
    value         = "1"
    default_value = "0"
  }
}

resource "aws_cloudwatch_metric_alarm" "high_error_volume" {
  alarm_name         = "${var.name}-high-error-count"
  alarm_description  = "Triggers alarm if there are more than 5 errors in the last 5 minutes"
  namespace          = "${var.name}Metrics"
  metric_name        = "ErrorCount"
  statistic          = "Sum"
  period             = "300"
  evaluation_periods = "1"
  # add sns topic later
  #  alarm_actions       = [aws_sns_topic.alerting.arn]
  #  ok_actions          = [aws_sns_topic.alerting.arn]
  threshold           = "10"
  treat_missing_data  = "missing"
  comparison_operator = "GreaterThanThreshold"
}
