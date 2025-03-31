# SNS Topics for linking to Alarms
resource "aws_sns_topic" "email_topic" {
  #checkov:skip=CKV_AWS_26: "SNS topic encryption is not required as no sensitive data is processed through it"
  name = "email-topic"
}

resource "aws_sns_topic" "dacp_utilisation_alarm" {
  #checkov:skip=CKV_AWS_26: "SNS topic encryption is not required as no sensitive data is processed through it"
  name = "dacp_utilisation_alarm"
}

# SNS Topic Subscriptions to configure alarm actions
resource "aws_sns_topic_subscription" "email_subscription" {
  #checkov:skip=CKV_AWS_26: "SNS topic encryption is not required as no sensitive data is processed through it"
  topic_arn = aws_sns_topic.email_topic.arn
  protocol  = "email"
  endpoint  = local.application_data.accounts[local.environment].support_email
}

# Define the metrics in ContainerInsights (for ECS Fargate)
resource "aws_cloudwatch_metric_alarm" "ecs_service_high_ram_alarm" {
  alarm_name          = "ecs_service_high_ram_alarm"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = 3
  metric_name         = "MemoryUtilized"
  namespace           = "ECS/ContainerInsights"
  period              = 60
  statistic           = "Average"
  threshold           = 2500
  alarm_description   = "DACP ECS scaling up as memory has exceeded the threshold"
  alarm_actions = [
    aws_appautoscaling_policy.scale_up_amber.arn,
    aws_sns_topic.dacp_utilisation_alarm.arn,
    aws_sns_topic.email_topic.arn
  ]
  dimensions = {
    ClusterName = "dacp_cluster"
    ServiceName = var.networking[0].application
  }
}

resource "aws_cloudwatch_metric_alarm" "ecs_service_normal_ram_alarm" {
  alarm_name          = "ecs_service_normal_ram_alarm"
  comparison_operator = "LessThanThreshold"
  evaluation_periods  = 3
  metric_name         = "MemoryUtilized"
  namespace           = "ECS/ContainerInsights"
  period              = 60
  statistic           = "Average"
  threshold           = 2500
  alarm_description   = "DACP ECS scaling down as memory has returned to normal levels"
  alarm_actions = [
    aws_appautoscaling_policy.scale_down_amber.arn,
    aws_sns_topic.dacp_utilisation_alarm.arn,
    aws_sns_topic.email_topic.arn
  ]
  dimensions = {
    ClusterName = "dacp_cluster"
    ServiceName = var.networking[0].application
  }
}

resource "aws_cloudwatch_metric_alarm" "ecs_cpu_alarm" {
  alarm_name          = "ecs-cpu-utilization-alarm"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = "2"
  metric_name         = "CpuUtilized"
  namespace           = "ECS/ContainerInsights"
  period              = "120"
  statistic           = "Average"
  threshold           = "100"
  alarm_description   = "This metric checks if CPU utilization is high - threshold set to 80%"
  alarm_actions       = [aws_sns_topic.dacp_utilisation_alarm.arn]
  dimensions = {
    ClusterName = aws_ecs_cluster.dacp_cluster.name
  }
}