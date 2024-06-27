# Terraform alarms for ECS Cluster
locals {
  cluster_name = split("/", var.ecs_cluster_arn)[1]
}
# Alarm for high CPU usage
resource "aws_cloudwatch_metric_alarm" "ecs_cpu_over_threshold" {
  alarm_name          = "${var.name}-${var.env_name}-ecs-cpu-threshold"
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
        ServiceName = var.name
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
  alarm_name          = "${var.name}-${var.env_name}-ecs-memory-threshold"
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
        ServiceName = var.name
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
  count          = var.log_error_pattern != "" ? 1 : 0
  log_group_name = aws_cloudwatch_log_group.ecs.name
  name           = "${var.name}-${var.env_name}-logged-errors"
  pattern        = var.log_error_pattern
  metric_transformation {
    name          = "${var.name}-${var.env_name}-logged-errors"
    namespace     = "${var.env_name}/${var.name}"
    value         = 1
    default_value = 0
  }
}

resource "aws_cloudwatch_metric_alarm" "high_error_volume" {
  count               = var.log_error_pattern != "" ? 1 : 0
  alarm_name          = "${var.name}-${var.env_name}-high-error-count"
  alarm_description   = "Triggers alarm if there are more than 10 errors in the last 5 minutes"
  namespace           = "${var.env_name}/${var.name}"
  metric_name         = "${var.name}-${var.env_name}-logged-errors"
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
  count               = var.log_error_pattern != "" ? 1 : 0
  alarm_name          = "${var.name}-${var.env_name}-warning-error-count"
  alarm_description   = "Triggers alarm if there are more than 5 errors in the last 2 minutes"
  namespace           = "${var.env_name}/${var.name}"
  metric_name         = "${var.name}-${var.env_name}-logged-errors"
  statistic           = "Sum"
  period              = "120"
  evaluation_periods  = "1"
  alarm_actions       = [var.sns_topic_arn]
  ok_actions          = [var.sns_topic_arn]
  threshold           = "5"
  treat_missing_data  = "missing"
  comparison_operator = "GreaterThanThreshold"
}

resource "aws_cloudwatch_metric_alarm" "healthy_hosts_fatal_alarm" {
  alarm_name          = "${var.name}-${var.env_name}-healthy-hosts-fatal"
  alarm_description   = "All `${var.name}` instances stopped responding."
  namespace           = "AWS/ApplicationELB"
  statistic           = "Minimum"
  metric_name         = "HealthyHostCount"
  comparison_operator = "LessThanThreshold"
  threshold           = 1
  evaluation_periods  = 2
  period              = 60
  alarm_actions       = [var.sns_topic_arn]
  ok_actions          = [var.sns_topic_arn]
  dimensions = {
    LoadBalancer = var.frontend_lb_arn_suffix
    TargetGroup  = aws_lb_target_group.frontend.arn_suffix
  }
}

# Response time alarms
resource "aws_cloudwatch_metric_alarm" "response_time_critical_alarm" {
  alarm_name          = "${var.name}-${var.env_name}-response-time-critical"
  alarm_description   = "Average response time for the `${var.name}` service exceeded 5 seconds."
  namespace           = "AWS/ApplicationELB"
  statistic           = "Average"
  metric_name         = "TargetResponseTime"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  threshold           = 5
  evaluation_periods  = 1
  period              = 300
  alarm_actions       = [var.sns_topic_arn]
  ok_actions          = [var.sns_topic_arn]
  dimensions = {
    LoadBalancer = var.frontend_lb_arn_suffix
    TargetGroup  = aws_lb_target_group.frontend.arn_suffix
  }
}

# Response code alarms
resource "aws_cloudwatch_metric_alarm" "response_code_5xx_warning_alarm" {
  alarm_name          = "${var.name}-${var.env_name}-5xx-response-warning"
  alarm_description   = "The `${var.name}` service responded with 5xx errors."
  namespace           = "AWS/ApplicationELB"
  statistic           = "Sum"
  metric_name         = "HTTPCode_Target_5XX_Count"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  threshold           = 1
  evaluation_periods  = 2
  period              = 60
  alarm_actions       = [var.sns_topic_arn]
  ok_actions          = [var.sns_topic_arn]
  dimensions = {
    LoadBalancer = var.frontend_lb_arn_suffix
    TargetGroup  = aws_lb_target_group.frontend.arn_suffix
  }
}

resource "aws_cloudwatch_metric_alarm" "response_code_5xx_critical_alarm" {
  alarm_name          = "${var.name}-${var.env_name}-5xx-response-critical"
  alarm_description   = "The `${var.name}` service responded with 5xx errors at an elevated rate (over 10/minute)."
  namespace           = "AWS/ApplicationELB"
  statistic           = "Sum"
  metric_name         = "HTTPCode_Target_5XX_Count"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  threshold           = 10
  evaluation_periods  = 2
  period              = 60
  alarm_actions       = [var.sns_topic_arn]
  ok_actions          = [var.sns_topic_arn]
  dimensions = {
    LoadBalancer = var.frontend_lb_arn_suffix
    TargetGroup  = aws_lb_target_group.frontend.arn_suffix
  }
}

resource "aws_cloudwatch_metric_alarm" "ecs_running_tasks_less_than_desired" {
  alarm_name          = "${var.name}-${var.env_name}-running-tasks-lt-desired"
  actions_enabled     = true
  alarm_actions       = [var.sns_topic_arn]
  ok_actions          = [var.sns_topic_arn]
  evaluation_periods  = 1
  datapoints_to_alarm = 1
  threshold           = 1
  comparison_operator = "GreaterThanOrEqualToThreshold"
  treat_missing_data  = "missing"

  metric_query {
    id          = "e1"
    label       = "Expression1"
    return_data = true
    expression  = "IF(m1 < m2, 1, 0)"
  }

  metric_query {
    id          = "m1"
    return_data = false
    metric {
      namespace   = "ECS/ContainerInsights"
      metric_name = "RunningTaskCount"
      dimensions = {
        ServiceName = var.name
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
        ServiceName = var.name
        ClusterName = local.cluster_name
      }
      period = 300
      stat   = "Sum"
    }
  }
}
