# SNS Topics for linking to Alarms
resource "aws_sns_topic" "email_topic" {
  count = local.is-development ? 0 : 1
  name  = "email-topic"
}

resource "aws_sns_topic" "ddos_alarm" {
  count = local.is-development ? 0 : 1
  name  = "dacp_ddos_alarm"
}

resource "aws_sns_topic" "dacp_utilisation_alarm" {
  count = local.is-development ? 0 : 1
  name  = "dacp_utilisation_alarm"
}

# SNS Topic Subscriptions to configure alarm actions
resource "aws_sns_topic_subscription" "email_subscription" {
  count     = local.is-development ? 0 : 1
  topic_arn = aws_sns_topic.email_topic.arn
  protocol  = "email"
  endpoint  = local.application_data.accounts[local.environment].support_email
}

# Define the metrics in ContainerInsights (for ECS Fargate)
resource "aws_cloudwatch_metric_alarm" "ecs_service_high_ram_alarm" {
  count               = local.is-development ? 0 : 1
  alarm_name          = "ecs_service_high_ram_alarm"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = 3
  metric_name         = "MemoryUtilized"
  namespace           = "ECS/ContainerInsights"
  period              = 60
  statistic           = "Average"
  threshold           = 1500
  alarm_description   = "This alarm monitors Memory utilization of an ECS Fargate service (in MB)"
  alarm_actions       = [
                          aws_appautoscaling_policy.scale_up_amber.arn,
                          aws_sns_topic.dacp_utilisation_alarm[0].arn,
                          aws_sns_topic.email_topic.arn
  ]
  dimensions = {
    ClusterName = "dacp_cluster"
    ServiceName = var.networking[0].application
  }
}

resource "aws_cloudwatch_metric_alarm" "ecs_service_normal_ram_alarm" {
  count               = local.is-development ? 0 : 1
  alarm_name          = "ecs_service_normal_ram_alarm"
  comparison_operator = "LowerThanThreshold"
  evaluation_periods  = 3
  metric_name         = "MemoryUtilized"
  namespace           = "ECS/ContainerInsights"
  period              = 60
  statistic           = "Average"
  threshold           = 1500
  alarm_description   = "This alarm monitors Memory utilization of an ECS Fargate service"
  alarm_actions       = [
    aws_appautoscaling_policy.scale_down_amber.arn,
    aws_sns_topic.dacp_utilisation_alarm[0].arn,
    aws_sns_topic.email_topic.arn
  ]
  dimensions = {
    ClusterName = "dacp_cluster"
    ServiceName = var.networking[0].application
  }
}

resource "aws_cloudwatch_metric_alarm" "ecs_cpu_alarm" {
  count               = local.is-development ? 0 : 1
  alarm_name          = "ecs-cpu-utilization-alarm"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = "2"
  metric_name         = "CpuUtilized"
  namespace           = "ECS/ContainerInsights"
  period              = "120"
  statistic           = "Average"
  threshold           = "500"
  alarm_description   = "This metric checks if CPU utilization is high - threshold set to 80%"
  alarm_actions       = [aws_sns_topic.dacp_utilisation_alarm[0].arn]
  dimensions = {
    ClusterName = aws_ecs_cluster.dacp_cluster.name
  }
}

resource "aws_cloudwatch_metric_alarm" "ddos_attack_external" {
  count               = local.is-development ? 0 : 1
  alarm_name          = "DDoSDetected"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "3"
  metric_name         = "DDoSDetected"
  namespace           = "AWS/DDoSProtection"
  period              = "60"
  statistic           = "Average"
  threshold           = "0"
  alarm_description   = "Triggers when AWS Shield Advanced detects a DDoS attack"
  treat_missing_data  = "notBreaching"
  alarm_actions       = [aws_sns_topic.ddos_alarm[0].arn]
  dimensions = {
    ResourceArn = aws_lb.dacp_lb.arn
  }
}


