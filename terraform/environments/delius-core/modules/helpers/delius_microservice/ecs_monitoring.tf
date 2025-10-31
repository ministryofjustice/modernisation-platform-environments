# Terraform alarms for ECS Cluster
locals {
  cluster_name = split("/", var.ecs_cluster_arn)[1]
}

# Alarm for critical CPU usage
resource "aws_cloudwatch_metric_alarm" "ecs_cpu_over_critical_threshold" {
  alarm_name          = "${var.name}-${var.env_name}-ecs-cpu-critical-threshold"
  alarm_description   = "Triggers alarm if ECS CPU crosses a critical threshold"
  namespace           = "AWS/ECS"
  metric_name         = "CPUUtilization"
  statistic           = "Average"
  period              = "60"
  evaluation_periods  = "5"
  alarm_actions       = [var.sns_topic_arn]
  ok_actions          = [var.sns_topic_arn]
  threshold           = "90"
  treat_missing_data  = "missing"
  comparison_operator = "GreaterThanThreshold"

  dimensions = {
    ServiceName = var.name
    ClusterName = local.cluster_name
  }
}

# Alarm for critical memory usage
resource "aws_cloudwatch_metric_alarm" "ecs_memory_over_critical_threshold" {
  alarm_name          = "${var.name}-${var.env_name}-ecs-memory-critical-threshold"
  alarm_description   = "Triggers alarm if ECS memory crosses a critical threshold"
  namespace           = "AWS/ECS"
  metric_name         = "MemoryUtilization"
  statistic           = "Average"
  period              = "60"
  evaluation_periods  = "5"
  alarm_actions       = [var.sns_topic_arn]
  ok_actions          = [var.sns_topic_arn]
  threshold           = "90"
  treat_missing_data  = "missing"
  comparison_operator = "GreaterThanThreshold"

  dimensions = {
    ServiceName = var.name
    ClusterName = local.cluster_name
  }

}

# Alarm for warning CPU usage
resource "aws_cloudwatch_metric_alarm" "ecs_cpu_over_warning_threshold" {
  alarm_name          = "${var.name}-${var.env_name}-ecs-cpu-threshold"
  alarm_description   = "Triggers alarm if ECS CPU crosses a threshold"
  namespace           = "AWS/ECS"
  metric_name         = "MemoryUtilization"
  statistic           = "Average"
  period              = "60"
  evaluation_periods  = "5"
  alarm_actions       = [var.sns_topic_arn]
  ok_actions          = [var.sns_topic_arn]
  threshold           = "80"
  treat_missing_data  = "missing"
  comparison_operator = "GreaterThanThreshold"

  dimensions = {
    ServiceName = var.name
    ClusterName = local.cluster_name
  }
}

# Alarm for warning memory usage
resource "aws_cloudwatch_metric_alarm" "ecs_memory_over_warning_threshold" {
  alarm_name          = "${var.name}-${var.env_name}-ecs-memory-threshold"
  alarm_description   = "Triggers alarm if ECS memory crosses a threshold"
  namespace           = "AWS/ECS"
  metric_name         = "CPUUtilization"
  statistic           = "Average"
  period              = "60"
  evaluation_periods  = "5"
  alarm_actions       = [var.sns_topic_arn]
  ok_actions          = [var.sns_topic_arn]
  threshold           = "80"
  treat_missing_data  = "missing"
  comparison_operator = "GreaterThanThreshold"

  dimensions = {
    ServiceName = var.name
    ClusterName = local.cluster_name
  }
}

resource "aws_cloudwatch_log_metric_filter" "ecs_log_error_filter" {
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

resource "aws_cloudwatch_metric_alarm" "ecs_critical_error_volume" {
  count               = var.log_error_pattern != "" ? 1 : 0
  alarm_name          = "${var.name}-${var.env_name}-critical-error-count"
  alarm_description   = "Critical alarm for log error threshold"
  namespace           = "${var.env_name}/${var.name}"
  metric_name         = "${var.name}-${var.env_name}-logged-errors"
  statistic           = "Sum"
  period              = var.log_error_threshold_config.critical.period
  evaluation_periods  = "1"
  alarm_actions       = [var.sns_topic_arn]
  ok_actions          = [var.sns_topic_arn]
  threshold           = var.log_error_threshold_config.critical.threshold
  treat_missing_data  = "missing"
  comparison_operator = "GreaterThanThreshold"
}

resource "aws_cloudwatch_metric_alarm" "ecs_warning_error_volume" {
  count               = var.log_error_pattern != "" ? 1 : 0
  alarm_name          = "${var.name}-${var.env_name}-warning-error-count"
  alarm_description   = "Warning alarm for log error threshold"
  namespace           = "${var.env_name}/${var.name}"
  metric_name         = "${var.name}-${var.env_name}-logged-errors"
  statistic           = "Sum"
  period              = var.log_error_threshold_config.warning.period
  evaluation_periods  = "1"
  alarm_actions       = [var.sns_topic_arn]
  ok_actions          = [var.sns_topic_arn]
  threshold           = var.log_error_threshold_config.warning.threshold
  treat_missing_data  = "missing"
  comparison_operator = "GreaterThanThreshold"
}

resource "aws_cloudwatch_metric_alarm" "ecs_healthy_hosts_fatal_alarm" {
  count               = var.microservice_lb != null ? 1 : 0
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
    TargetGroup  = aws_lb_target_group.frontend[0].arn_suffix
  }
}

# Response time alarms
resource "aws_cloudwatch_metric_alarm" "alb_response_time_critical_alarm" {
  count               = var.microservice_lb != null ? 1 : 0
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
    TargetGroup  = aws_lb_target_group.frontend[0].arn_suffix
  }
}

# Response code alarms
resource "aws_cloudwatch_metric_alarm" "alb_response_code_5xx_warning_alarm" {
  count               = var.microservice_lb != null ? 1 : 0
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
    TargetGroup  = aws_lb_target_group.frontend[0].arn_suffix
  }
}

resource "aws_cloudwatch_metric_alarm" "alb_response_code_5xx_critical_alarm" {
  count               = var.microservice_lb != null ? 1 : 0
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
    TargetGroup  = aws_lb_target_group.frontend[0].arn_suffix
  }
}

resource "aws_cloudwatch_metric_alarm" "ecs_running_tasks_less_than_desired" {
  alarm_name          = "${var.name}-${var.env_name}-running-tasks-lt-desired"
  actions_enabled     = true
  alarm_actions       = [var.sns_topic_arn]
  ok_actions          = [var.sns_topic_arn]
  evaluation_periods  = 1
  datapoints_to_alarm = 1
  period              = 60
  comparison_operator = "LessThanThreshold"
  threshold           = var.desired_count
  treat_missing_data  = "missing"
  metric_name         = "RunningTaskCount"
  namespace           = "ECS/ContainerInsights"
  statistic           = "Minimum"

  dimensions = {
    ServiceName = var.name
    ClusterName = local.cluster_name
  }
}
