######################################
# ECS CLOUDWATCH GROUP
######################################
variable "ecs_cpu_alarm_threshold" {
  type = number
  default = 75
}
variable "ecs_memory_alarm_threshold" {
  type = number
  default = 75
}
variable "alb_target_response_time_threshold" {
  type = number
  default = 10
}
variable "alb_target_response_time_threshold_maximum" {
  type = number
  default = 60
}
variable "alb_unhealthy_alarm_threshold" {
  type = number
  default = 0
}
variable "alb_rejected_alarm_threshold" {
  type = number
  default = 10
}
variable "alb_target_5xx_alarm_threshold" {
  type = number
  default = 10
}
variable "alb_5xx_alarm_threshold" {
  type = number
  default = 10
}
variable "alb_target_4xx_alarm_threshold" {
  type = number
  default = 10
}
variable "alb_4xx_alarm_threshold" {
  type = number
  default = 10
}
resource "aws_cloudwatch_log_group" "maat_api_ecs_cw_group" {
  name              = "${local.application_name}-ECS"
  retention_in_days = 90
  kms_key_id = aws_kms_key.cloudwatch_logs_key.arn
}
# ECS cluster alerting
resource "aws_cloudwatch_metric_alarm" "ecs_cpu_over_threshold" {
  alarm_name          = "${local.application_name}-ECS-CPU-high-threshold-alarm1"
  alarm_description   = "If the CPU exceeds the predefined threshold, this alarm will trigger. Please investigate."
  namespace           = "AWS/ECS"
  metric_name         = "CPUUtilization"
  statistic           = "Average"
  period              = 60
  evaluation_periods  = 5
  threshold           = var.ecs_cpu_alarm_threshold
  treat_missing_data  = "breaching"
  alarm_actions       = [aws_sns_topic.maat_api_alerting_topic.arn]
  ok_actions          = [aws_sns_topic.maat_api_alerting_topic.arn]
  unit                = "Percent"
  dimensions = {
    ClusterName = aws_ecs_cluster.app_ecs_cluster.name
    ServiceName = aws_ecs_service.maat_api_ecs_service.name
  }
  comparison_operator = "GreaterThanThreshold"
}

resource "aws_cloudwatch_metric_alarm" "ecs_memory_over_threshold" {
  alarm_name          = "${local.application_name}-ECS-Memory-high-threshold-alarm"
  alarm_description   = "If the memory util exceeds the predefined threshold, this alarm will trigger. Please investigate."
  namespace           = "AWS/ECS"
  metric_name         = "MemoryUtilization"
  statistic           = "Average"
  period              = 60
  evaluation_periods  = 5
  threshold           = var.ecs_memory_alarm_threshold
  treat_missing_data  = "breaching"
  alarm_actions       = [aws_sns_topic.maat_api_alerting_topic.arn]
  ok_actions          = [aws_sns_topic.maat_api_alerting_topic.arn]
  unit                = "Percent"
  dimensions = {
    ClusterName = aws_ecs_cluster.app_ecs_cluster.name
    ServiceName = aws_ecs_service.maat_api_ecs_service.name
  }
  comparison_operator = "GreaterThanThreshold"
}

# Application Load Balancer Alerting
resource "aws_cloudwatch_metric_alarm" "target_response_time" {
  alarm_name          = "${local.application_name}-alb-target-response-time-alarm"
  alarm_description   = "The time elapsed, in seconds, after the request leaves the load balancer until a response from the target is received"
  namespace           = "AWS/ApplicationELB"
  metric_name         = "TargetResponseTime"
  extended_statistic  = "p99"
  period              = 60
  evaluation_periods  = 5
  threshold           = var.alb_target_response_time_threshold
  treat_missing_data  = "notBreaching"
  alarm_actions       = [aws_sns_topic.maat_api_alerting_topic.arn]
  ok_actions          = [aws_sns_topic.maat_api_alerting_topic.arn]
  dimensions = {
    LoadBalancer = var.LoadBalancer.LoadBalancerFullName
  }
  comparison_operator = "GreaterThanThreshold"
}

resource "aws_cloudwatch_metric_alarm" "target_response_time_maximum" {
  alarm_name          = "${local.application_name}-alb-target-response-time-alarm-maximum"
  alarm_description   = "The time elapsed, in seconds, after the request leaves the load balancer until a response from the target is received. Triggered if the response is longer than 60s."
  namespace           = "AWS/ApplicationELB"
  metric_name         = "TargetResponseTime"
  statistic           = "Maximum"
  period              = 60
  evaluation_periods  = 1
  threshold           = var.alb_target_response_time_threshold_maximum
  treat_missing_data  = "notBreaching"
  alarm_actions       = [aws_sns_topic.maat_api_alerting_topic.arn]
  ok_actions          = [aws_sns_topic.maat_api_alerting_topic.arn]
  dimensions = {
    LoadBalancer = aws_lb.maat_api_ecs_lb.name
  }
  comparison_operator = "GreaterThanThreshold"
}

resource "aws_cloudwatch_metric_alarm" "unhealthy_hosts" {
  alarm_name          = "${local.application_name}-unhealthy-hosts-alarm"
  alarm_description   = "The unhealthy hosts alarm triggers if your load balancer recognizes there is an unhealthy host and has been there for over 15 minutes."
  namespace           = "AWS/ApplicationELB"
  metric_name         = "UnHealthyHostCount"
  statistic           = "Average"
  period              = 60
  evaluation_periods  = 5
  threshold           = var.alb_unhealthy_alarm_threshold
  treat_missing_data  = "notBreaching"
  alarm_actions       = [aws_sns_topic.maat_api_alerting_topic.arn]
  ok_actions          = [aws_sns_topic.maat_api_alerting_topic.arn]
  dimensions = {
    LoadBalancer = aws_lb.maat_api_ecs_lb.name
    TargetGroup  = aws_lb_target_group.maat_api_ecs_target_group.name
  }
  comparison_operator = "GreaterThanThreshold"
}

resource "aws_cloudwatch_metric_alarm" "rejected_connection_count" {
  alarm_name          = "${local.application_name}-RejectedConnectionCount-alarm"
  alarm_description   = "There is no surge queue on ALB's. Alert triggers in ALB rejects too many requests, usually due to the backend being busy."
  namespace           = "AWS/ApplicationELB"
  metric_name         = "RejectedConnectionCount"
  statistic           = "Sum"
  period              = 60
  evaluation_periods  = 5
  threshold           = var.alb_rejected_alarm_threshold
  treat_missing_data  = "notBreaching"
  alarm_actions       = [aws_sns_topic.maat_api_alerting_topic.arn]
  ok_actions          = [aws_sns_topic.maat_api_alerting_topic.arn]
  dimensions = {
    LoadBalancer = aws_lb.maat_api_ecs_lb.name
  }
  comparison_operator = "GreaterThanThreshold"
}

resource "aws_cloudwatch_metric_alarm" "http_5xx_error" {
  alarm_name          = "${local.application_name}-http-5xx-error-alarm"
  alarm_description   = "This alarm will trigger if we receive 4 5XX http alerts in a 5-minute period."
  namespace           = "AWS/ApplicationELB"
  metric_name         = "HTTPCode_Target_5XX_Count"
  statistic           = "Sum"
  period              = 60
  evaluation_periods  = 5
  threshold           = var.alb_target_5xx_alarm_threshold
  treat_missing_data  = "notBreaching"
  alarm_actions       = [aws_sns_topic.maat_api_alerting_topic.arn]
  ok_actions          = [aws_sns_topic.maat_api_alerting_topic.arn]
  dimensions = {
    LoadBalancer = aws_lb.maat_api_ecs_lb.name
  }
  comparison_operator = "GreaterThanThreshold"
}

resource "aws_cloudwatch_metric_alarm" "application_elb_5xx_error" {
  alarm_name          = "${local.application_name}-elb-5xx-error-alarm"
  alarm_description   = "This alarm will trigger if we receive 4 5XX elb alerts in a 5-minute period."
  namespace           = "AWS/ApplicationELB"
  metric_name         = "HTTPCode_ELB_5XX_Count"
  statistic           = "Sum"
  period              = 60
  evaluation_periods  = 5
  threshold           = var.alb_5xx_alarm_threshold
  treat_missing_data  = "notBreaching"
  alarm_actions       = [aws_sns_topic.maat_api_alerting_topic.arn]
  ok_actions          = [aws_sns_topic.maat_api_alerting_topic.arn]
  dimensions = {
    LoadBalancer = aws_lb.maat_api_ecs_lb.name
  }
  comparison_operator = "GreaterThanThreshold"
}

resource "aws_cloudwatch_metric_alarm" "http4xxError" {
  alarm_name          = "${local.application_name}-http-4xx-error-alarm"
  alarm_description   = "This alarm will trigger if we receive 4 4XX http alerts in a 5-minute period."
  namespace           = "AWS/ApplicationELB"
  metric_name         = "HTTPCode_Target_4XX_Count"
  statistic           = "Sum"
  period              = 60
  evaluation_periods  = 5
  threshold           = var.alb_target_4xx_alarm_threshold
  treat_missing_data  = "notBreaching"
  alarm_actions       = [aws_sns_topic.maat_api_alerting_topic.arn]
  ok_actions          = [aws_sns_topic.maat_api_alerting_topic.arn]
  dimensions = {
    LoadBalancer = aws_lb.maat_api_ecs_lb.name
  }
  comparison_operator = "GreaterThanThreshold"
}

resource "aws_cloudwatch_metric_alarm" "application_elb_4xx_error" {
  alarm_name          = "${local.application_name}-elb-4xx-error-alarm"
  alarm_description   = "This alarm will trigger if we receive 4 4XX elb alerts in a 5-minute period."
  namespace           = "AWS/ApplicationELB"
  metric_name         = "HTTPCode_ELB_4XX_Count"
  statistic           = "Sum"
  period              = 60
  evaluation_periods  = 5
  threshold           = var.alb_4xx_alarm_threshold
  treat_missing_data  = "notBreaching"
  alarm_actions       = [aws_sns_topic.maat_api_alerting_topic.arn]
  ok_actions          = [aws_sns_topic.maat_api_alerting_topic.arn]
  dimensions = {
    LoadBalancer = aws_lb.maat_api_ecs_lb.name
  }
  comparison_operator = "GreaterThanThreshold"
}

# SNS topic for monitoring to send alarms to
resource "aws_sns_topic" "maat_api_alerting_topic" {
  name = "${local.application_name}-${local.environment}-alerting-topic"
}

resource "aws_sns_topic_subscription" "pagerduty_subscription" {
  topic_arn = aws_sns_topic.maat_api_alerting_topic.arn
  protocol  = "https"
  endpoint  = "https://events.pagerduty.com/integration/${local.pagerduty_integration_keys[local.pagerduty_integration_key_name]}/enqueue"
}

# Pager duty integration

# Get the map of pagerduty integration keys from the modernisation platform account
data "aws_secretsmanager_secret" "pagerduty_integration_keys" {
  provider = aws.modernisation-platform
  name     = "pagerduty_integration_keys"
}
data "aws_secretsmanager_secret_version" "pagerduty_integration_keys" {
  provider  = aws.modernisation-platform
  secret_id = data.aws_secretsmanager_secret.pagerduty_integration_keys.id
}

# Add a local to get the keys
locals {
  pagerduty_integration_keys = jsondecode(data.aws_secretsmanager_secret_version.pagerduty_integration_keys.secret_string)
  pagerduty_integration_key_name = local.application_data.accounts[local.environment].pagerduty_integration_key_name
}

# link the sns topic to the service
module "pagerduty_core_alerts_non_prod" {
  depends_on = [
    aws_sns_topic.maat_api_alerting_topic
  ]
  source                    = "github.com/ministryofjustice/modernisation-platform-terraform-pagerduty-integration?ref=v2.0.0"
  sns_topics                = [aws_sns_topic.maat_api_alerting_topic.name]
  pagerduty_integration_key = local.pagerduty_integration_keys["laa_maat_api_nonprod_alarms"]
}

module "pagerduty_core_alerts_prod" {
  depends_on = [
    aws_sns_topic.maat_api_alerting_topic
  ]
  source                    = "github.com/ministryofjustice/modernisation-platform-terraform-pagerduty-integration?ref=v2.0.0"
  sns_topics                = [aws_sns_topic.maat_api_alerting_topic.name]
  pagerduty_integration_key = local.pagerduty_integration_keys["laa_maat_api_prod_alarms"]
}