# CloudWatch Alarm for EDRMS Container Count
resource "aws_cloudwatch_metric_alarm" "container_count" {
  alarm_name                = "${local.application_name}-ecs-task-count"
  alarm_description         = "The number of EDRMS ECS tasks is less than ${local.application_data.accounts[local.environment].app_count}, Runbook - https://dsdmoj.atlassian.net/wiki/spaces/CCMS/pages/1408598133/Monitoring+and+Alerts"
  comparison_operator       = "LessThanThreshold"
  metric_name               = "DesiredTaskCount"
  namespace                 = "ECS/ContainerInsights"
  statistic                 = "Average"
  period                    = 300
  evaluation_periods        = 1
  datapoints_to_alarm       = 1
  threshold                 = local.application_data.accounts[local.environment].app_count
  treat_missing_data        = "missing"
  alarm_actions             = [aws_sns_topic.cloudwatch_slack.arn]
  ok_actions                = [aws_sns_topic.cloudwatch_slack.arn]
  insufficient_data_actions = []

  dimensions = {
    ServiceName = local.application_name
    ClusterName = "${local.application_name}-cluster"
  }

  tags = local.tags
}

# CloudWatch Alarm for EDRMS Unhealthy Hosts
resource "aws_cloudwatch_metric_alarm" "edrms_UnHealthy_Hosts" {
  alarm_name          = "${local.application_name}-unhealthy-hosts"
  alarm_description   = "There is an unhealthy host in the edrms target group for over 15min, Runbook - https://dsdmoj.atlassian.net/wiki/spaces/CCMS/pages/1408598133/Monitoring+and+Alerts"
  comparison_operator = "GreaterThanThreshold"
  metric_name         = "UnHealthyHostCount"
  statistic           = "Average"
  namespace           = "AWS/ApplicationELB"
  period              = "60"
  evaluation_periods  = "5"
  threshold           = "0"
  treat_missing_data  = "notBreaching"
  dimensions = {
    LoadBalancer = aws_lb.edrms.arn_suffix
    TargetGroup  = aws_lb_target_group.edrms_target_group.arn_suffix
  }

  alarm_actions = [aws_sns_topic.cloudwatch_slack.arn]
  ok_actions    = [aws_sns_topic.cloudwatch_slack.arn]

  tags = local.tags
}

# Underlying EC2 Instance Status Check Failure
resource "aws_cloudwatch_metric_alarm" "Status_Check_Failure" {
  alarm_name          = "${local.application_name}-status-check-failure"
  alarm_description   = "A edrms cluster EC2 instance has failed a status check, Runbook - https://dsdmoj.atlassian.net/wiki/spaces/CCMS/pages/1408598133/Monitoring+and+Alerts"
  comparison_operator = "GreaterThanThreshold"
  metric_name         = "StatusCheckFailed"
  statistic           = "Average"
  namespace           = "AWS/EC2"
  period              = "60"
  evaluation_periods  = "5"
  threshold           = "1"
  treat_missing_data  = "notBreaching"
  dimensions = {
    AutoScalingGroupName = aws_autoscaling_group.cluster-scaling-group.name
  }

  alarm_actions = [aws_sns_topic.cloudwatch_slack.arn]
  ok_actions    = [aws_sns_topic.cloudwatch_slack.arn]

  tags = local.tags
}

# TDS RDS CPU Utilization Alarm

resource "aws_cloudwatch_metric_alarm" "tds_rds_cpu_over_threshold" {
  alarm_name          = "${local.application_name}-tds-rds-cpu-high-threshold"
  alarm_description   = "TDS RDS CPU is above 85%, Runbook - https://dsdmoj.atlassian.net/wiki/spaces/CCMS/pages/1408598133/Monitoring+and+Alerts"
  comparison_operator = "GreaterThanThreshold"
  metric_name         = "CPUUtilization"
  statistic           = "Average"
  namespace           = "AWS/RDS"
  period              = "60"
  evaluation_periods  = "5"
  threshold           = "85"
  treat_missing_data  = "notBreaching"
  dimensions = {
    DBInstanceIdentifier = aws_db_instance.tds_db.id
  }

  alarm_actions = [aws_sns_topic.cloudwatch_slack.arn]
  ok_actions    = [aws_sns_topic.cloudwatch_slack.arn]

  tags = local.tags
}

# TDS RDS Free Storage Space Alarm
resource "aws_cloudwatch_metric_alarm" "TDS_RDS_Free_Storage_Space_Over_Threshold" {
  alarm_name          = "${local.application_name}-tds-rds-FreeStorageSpace-low-threshold"
  alarm_description   = "TDS RDS Free storage space is below 30, Runbook - https://dsdmoj.atlassian.net/wiki/spaces/CCMS/pages/1408598133/Monitoring+and+Alerts"
  comparison_operator = "LessThanThreshold"
  metric_name         = "FreeStorageSpace"
  statistic           = "Average"
  namespace           = "AWS/RDS"
  period              = "60"
  evaluation_periods  = "5"
  threshold           = "30"
  treat_missing_data  = "notBreaching"
  dimensions = {
    DBInstanceIdentifier = aws_db_instance.tds_db.id
  }

  alarm_actions = [aws_sns_topic.cloudwatch_slack.arn]
  ok_actions    = [aws_sns_topic.cloudwatch_slack.arn]

  tags = local.tags
}
