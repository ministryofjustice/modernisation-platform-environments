resource "aws_sns_topic" "alarm_topic" {
  count = local.is-development ? 0 : 1
  name  = "alarm-topic"
}

resource "aws_sns_topic_subscription" "email_subscription" {
  count     = local.is-development ? 0 : 1
  topic_arn = aws_sns_topic.alarm_topic.arn
  protocol  = "email"
  endpoint  = local.application_data.accounts[local.environment].support_email
}

resource "aws_cloudwatch_metric_alarm" "ecs_service_high_ram_alarm" {
  count               = local.is-development ? 0 : 1
  alarm_name          = "ecs_service_high_ram_alarm"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = 3
  #metric_name         = "CPUUtilization"
  metric_name         = "MemoryUtilization"
  namespace           = "AWS/ECS"
  period              = 60
  statistic           = "Average"
  threshold           = 20
  alarm_description   = "This alarm monitors Memory utilization of an ECS Fargate service"
  alarm_actions       = [
                          aws_appautoscaling_policy.scale_up_amber.arn,
                          aws_sns_topic.alarm_topic.arn
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
  #metric_name         = "CPUUtilization"
  metric_name         = "MemoryUtilization"
  namespace           = "AWS/ECS"
  period              = 60
  statistic           = "Average"
  threshold           = 20
  alarm_description   = "This alarm monitors Memory utilization of an ECS Fargate service"
  alarm_actions       = [
    aws_appautoscaling_policy.scale_down_amber.arn,
    aws_sns_topic.alarm_topic.arn
  ]
  dimensions = {
    ClusterName = "dacp_cluster"
    ServiceName = var.networking[0].application
  }
}

