#######################################
# CloudWatch Alarms for PUI
#######################################
# Alarm for ALB 5xx Errors
resource "aws_cloudwatch_metric_alarm" "alb_pui_5xx" {
  alarm_name          = "${local.application_name}-${local.environment}-pui-5xx-errors"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 3
  metric_name         = "HTTPCode_ELB_5XX_Count"
  namespace           = "AWS/ApplicationELB"
  period              = 60
  statistic           = "Sum"
  threshold           = 10
  alarm_description   = "Alarm when the number of 5xx errors from the pui ALB exceeds 10 in a 3 minute period"
  dimensions = {
    LoadBalancer = aws_lb.pui.name
  }
  treat_missing_data = "notBreaching"
  alarm_actions      = [aws_sns_topic.cloudwatch_alerts.arn]
  ok_actions         = [aws_sns_topic.cloudwatch_alerts.arn]

  tags = local.tags
}

# Alarm for ECS Container Count for pui Service
resource "aws_cloudwatch_metric_alarm" "container_pui_count" {
  alarm_name          = "${local.application_name}-${local.environment}-pui-container-count-low"
  comparison_operator = "LessThanThreshold"
  evaluation_periods  = 1
  metric_name         = "RunningTaskCount"
  namespace           = "ECS/ContainerInsights"
  period              = 60
  statistic           = "Average"
  threshold           = local.application_data.accounts[local.environment].pui_app_count
  dimensions = {
    ClusterName = aws_ecs_cluster.main.name
  }
  alarm_description         = "The number of PUI ECS tasks is less than ${local.application_data.accounts[local.environment].pui_app_count}. Runbook: https://dsdmoj.atlassian.net/wiki/spaces/CCMS/pages/1408598133/Monitoring+and+Alerts"
  treat_missing_data        = "breaching"
  alarm_actions             = [aws_sns_topic.cloudwatch_alerts.arn]
  ok_actions                = [aws_sns_topic.cloudwatch_alerts.arn]
  insufficient_data_actions = []

  tags = local.tags
}

# Underlying EC2 Instance Status Check Failure
resource "aws_cloudwatch_metric_alarm" "Status_Check_Failure" {
  alarm_name          = "${local.application_name}-${local.environment}-status-check-failure"
  alarm_description   = "A pui cluster EC2 instance has failed a status check, Runbook - https://dsdmoj.atlassian.net/wiki/spaces/CCMS/pages/1408598133/Monitoring+and+Alerts"
  comparison_operator = "GreaterThanThreshold"
  metric_name         = "StatusCheckFailed"
  statistic           = "Average"
  namespace           = "AWS/EC2"
  period              = "60"
  evaluation_periods  = "5"
  threshold           = "1"
  treat_missing_data  = "notBreaching"
  dimensions = {
    AutoScalingGroupName = aws_autoscaling_group.cluster_scaling_group.name
  }
  alarm_actions = [aws_sns_topic.cloudwatch_alerts.arn]
  ok_actions    = [aws_sns_topic.cloudwatch_alerts.arn]

  tags = local.tags
}

# Underlying clamav-ec2 Instance Status Check Failure
resource "aws_cloudwatch_metric_alarm" "Status_Check_Failure" {
  alarm_name          = "${local.application_name}-${local.environment}-status-check-failure"
  alarm_description   = "A pui cluster EC2 instance has failed a status check, Runbook - https://dsdmoj.atlassian.net/wiki/spaces/CCMS/pages/1408598133/Monitoring+and+Alerts"
  comparison_operator = "GreaterThanThreshold"
  metric_name         = "StatusCheckFailed"
  statistic           = "Average"
  namespace           = "AWS/EC2"
  period              = "60"
  evaluation_periods  = "5"
  threshold           = "1"
  treat_missing_data  = "notBreaching"
  dimensions = {
    InstanceId = aws_instance.ec2_clamav.id
  }
  alarm_actions = [aws_sns_topic.cloudwatch_alerts.arn]
  ok_actions    = [aws_sns_topic.cloudwatch_alerts.arn]

  tags = local.tags
}

# Underlying waf Instance Status Check Failure
resource "aws_cloudwatch_metric_alarm" "Status_Check_Failure" {
  alarm_name          = "${local.application_name}-${local.environment}-status-check-failure"
  alarm_description   = "A pui cluster EC2 instance has failed a status check, Runbook - https://dsdmoj.atlassian.net/wiki/spaces/CCMS/pages/1408598133/Monitoring+and+Alerts"
  comparison_operator = "GreaterThanThreshold"
  metric_name         = "StatusCheckFailed"
  statistic           = "Average"
  namespace           = "AWS/EC2"
  period              = "60"
  evaluation_periods  = "5"
  threshold           = "1"
  treat_missing_data  = "notBreaching"
  dimensions = {
    WebACL = aws_wafv2_web_acl.pui_web_acl.name
    Scope  = "REGIONAL"
  }
  alarm_actions = [aws_sns_topic.cloudwatch_alerts.arn]
  ok_actions    = [aws_sns_topic.cloudwatch_alerts.arn]

  tags = local.tags
}