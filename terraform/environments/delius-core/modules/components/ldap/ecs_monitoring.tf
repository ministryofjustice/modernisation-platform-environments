# Terraform alarms for ECS Cluster
locals {
  cluster_name = split("/", var.ecs_cluster_arn)[1]
}
# Alarm for high CPU usage
resource "aws_cloudwatch_metric_alarm" "cpu_over_threshold" {
  alarm_name          = "ldap-${var.env_name}-ecs-cpu-threshold"
  alarm_description   = "Triggers alarm if ECS CPU crosses a threshold"
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
    ClusterName = local.cluster_name
    ServiceName = local.cluster_name
  }

  tags = var.tags
}

# Alarm for high memory usage
resource "aws_cloudwatch_metric_alarm" "memory_over_threshold" {
  alarm_name          = "ldap-${var.env_name}-ecs-memory-threshold"
  alarm_description   = "Triggers alarm if ECS memory crosses a threshold"
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
    ClusterName = local.cluster_name
    ServiceName = local.cluster_name
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


# resource "aws_cloudwatch_metric_alarm" "log_error_warning_alarm" {
#   alarm_name          = "ldap-${var.env_name}-logged-errors-warning"
#   alarm_description   = "Error messages were detected in the `ldap` logs."
#   comparison_operator = "GreaterThanUpperThreshold"
#   threshold_metric_id = "ad1"
#   evaluation_periods  = 2
#   alarm_actions       = [var.sns_topic_arn]
#   ok_actions          = [var.sns_topic_arn]
#   actions_enabled     = true
#
#   metric_query {
#     id          = "ad1"
#     expression  = "ANOMALY_DETECTION_BAND(m1)"
#     label       = "${aws_cloudwatch_log_metric_filter.log_error_filter.metric_transformation.0.name} (expected)"
#     return_data = true
#   }
#
#   metric_query {
#     id          = "m1"
#     label       = aws_cloudwatch_log_metric_filter.log_error_filter.metric_transformation.0.name
#     return_data = true
#     metric {
#       namespace   = aws_cloudwatch_log_metric_filter.log_error_filter.metric_transformation.0.namespace
#       metric_name = aws_cloudwatch_log_metric_filter.log_error_filter.metric_transformation.0.name
#       period      = 300
#       stat        = "Sum"
#     }
#   }
# }
