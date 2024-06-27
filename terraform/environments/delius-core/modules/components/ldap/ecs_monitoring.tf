# Terraform alarms for ECS Cluster
locals {
  cluster_name = split("/", var.ecs_cluster_arn)[1]
}
# Alarm for high CPU usage
resource "aws_cloudwatch_metric_alarm" "ecs_cpu_over_threshold" {
  alarm_name          = "ldap-${var.env_name}-ecs-cpu-threshold"
  alarm_description   = "Triggers alarm if ECS CPU crosses a threshold"
  actions_enabled     = true
  alarm_actions       = [var.sns_topic_arn]
  ok_actions          = [var.sns_topic_arn]
  evaluation_periods  = 5
  datapoints_to_alarm = 5
  threshold_metric_id = "ad1"
  comparison_operator = "GreaterThanUpperThreshold"
  treat_missing_data  = "missing"

  metric_query {
    id          = "m1"
    return_data = true
    metric {
      namespace   = "AWS/ECS"
      metric_name = "CPUUtilization"
      dimensions = {
        ServiceName = "openldap"
        ClusterName = local.cluster_name
      }
      period = 60
      stat   = "Average"
    }
  }

  metric_query {
    id          = "ad1"
    label       = "CPUUtilization (expected)"
    return_data = true
    expression  = "ANOMALY_DETECTION_BAND(m1, 2)"
  }
}

# Alarm for high memory usage
resource "aws_cloudwatch_metric_alarm" "memory_over_threshold" {
  alarm_name          = "ldap-${var.env_name}-ecs-memory-threshold"
  alarm_description   = "Triggers alarm if ECS memory crosses a threshold"
  actions_enabled     = true
  alarm_actions       = [var.sns_topic_arn]
  ok_actions          = [var.sns_topic_arn]
  evaluation_periods  = 5
  datapoints_to_alarm = 5
  threshold_metric_id = "ad1"
  comparison_operator = "GreaterThanUpperThreshold"
  treat_missing_data  = "missing"

  metric_query {
    id          = "m1"
    return_data = true
    metric {
      namespace   = "AWS/ECS"
      metric_name = "MemoryUtilization"
      dimensions = {
        ServiceName = "openldap"
        ClusterName = local.cluster_name
      }
      period = 60
      stat   = "Average"
    }
  }

  metric_query {
    id          = "ad1"
    label       = "MemoryUtilization (expected)"
    return_data = true
    expression  = "ANOMALY_DETECTION_BAND(m1, 2)"
  }
}

resource "aws_cloudwatch_log_metric_filter" "log_error_filter" {
  name           = "ldap-${var.env_name}-error"
  pattern        = "%err=[1-9][0-9]+%"
  log_group_name = aws_cloudwatch_log_group.ldap_ecs.name

  metric_transformation {
    name          = "ErrorCount"
    namespace     = "ldapMetrics"
    value         = "1"
    default_value = "0"
  }
}

resource "aws_cloudwatch_metric_alarm" "high_error_volume" {
  alarm_name          = "ldap-${var.env_name}-high-error-count"
  alarm_description   = "Triggers alarm if there are more than 10 errors in the last 5 minutes"
  namespace           = "ldapMetrics"
  metric_name         = "ErrorCount"
  statistic           = "Sum"
  period              = "300"
  evaluation_periods  = "1"
  alarm_actions       = [var.sns_topic_arn]
  ok_actions          = [var.sns_topic_arn]
  threshold           = "10"
  treat_missing_data  = "missing"
  comparison_operator = "GreaterThanThreshold"
}

resource "aws_cloudwatch_metric_alarm" "warning_error_volume" {
  alarm_name          = "ldap-${var.env_name}-warning-error-count"
  alarm_description   = "Triggers alarm if there are more than 5 errors in the last 2 minutes"
  namespace           = "ldapMetrics"
  metric_name         = "ErrorCount"
  statistic           = "Sum"
  period              = "120"
  evaluation_periods  = "1"
  alarm_actions       = [var.sns_topic_arn]
  ok_actions          = [var.sns_topic_arn]
  threshold           = "5"
  treat_missing_data  = "missing"
  comparison_operator = "GreaterThanThreshold"
}

resource "aws_cloudwatch_metric_alarm" "ecs_running_tasks_less_than_desired" {
  alarm_name          = "ldap-${var.env_name}-running-tasks-lt-desired"
  actions_enabled     = true
  alarm_actions       = [var.sns_topic_arn]
  ok_actions          = [var.sns_topic_arn]
  evaluation_periods  = 1
  datapoints_to_alarm = 1
  threshold           = 0
  comparison_operator = "LessThanOrEqualToThreshold"
  treat_missing_data  = "missing"

  metric_query {
    id          = "e1"
    label       = "Expression1"
    return_data = true
    expression  = "IF(m1 < m2, 0, 1)"
  }

  metric_query {
    id          = "m1"
    return_data = false
    metric {
      namespace   = "ECS/ContainerInsights"
      metric_name = "RunningTaskCount"
      dimensions = {
        ServiceName = "openldap"
        ClusterName = local.cluster_name
      }
      period = 300
      stat   = "Sum"
    }
  }

  metric_query {
    id          = "m2"
    return_data = false
    metric {
      namespace   = "ECS/ContainerInsights"
      metric_name = "DesiredTaskCount"
      dimensions = {
        ServiceName = "openldap"
        ClusterName = local.cluster_name
      }
      period = 300
      stat   = "Sum"
    }
  }
}
