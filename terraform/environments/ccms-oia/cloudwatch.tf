#######################################
# CloudWatch Alarms for OIA
#######################################
# Alarm for ALB 5xx Errors
resource "aws_cloudwatch_metric_alarm" "alb_connector_5xx" {
  alarm_name          = "${local.application_name}-${local.environment}-connector-5xx-errors"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 3
  metric_name         = "HTTPCode_ELB_5XX_Count"
  namespace           = "AWS/ApplicationELB"
  period              = 60
  statistic           = "Sum"
  threshold           = 10
  alarm_description   = "Alarm when the number of 5xx errors from the connector ALB exceeds 10 in a 3 minute period"
  dimensions = {
    LoadBalancer = aws_lb.connector.name
  }
  treat_missing_data = "notBreaching"
  alarm_actions      = [aws_sns_topic.cloudwatch_alerts.arn]
  ok_actions         = [aws_sns_topic.cloudwatch_alerts.arn]

  tags = local.tags
}

resource "aws_cloudwatch_metric_alarm" "alb_opahub_5xx" {
  alarm_name          = "${local.application_name}-${local.environment}-opa-5xx-errors"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 3
  metric_name         = "HTTPCode_ELB_5XX_Count"
  namespace           = "AWS/ApplicationELB"
  period              = 60
  statistic           = "Sum"
  threshold           = 10
  alarm_description   = "Alarm when the number of 5xx errors from the connector ALB exceeds 10 in a 3 minute period"
  dimensions = {
    LoadBalancer = aws_lb.opahub.name
  }
  treat_missing_data = "notBreaching"
  alarm_actions      = [aws_sns_topic.cloudwatch_alerts.arn]
  ok_actions         = [aws_sns_topic.cloudwatch_alerts.arn]

  tags = local.tags
}

resource "aws_cloudwatch_metric_alarm" "alb_adaptor_5xx" {
  alarm_name          = "${local.application_name}-${local.environment}-adaptor-5xx-errors"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 3
  metric_name         = "HTTPCode_ELB_5XX_Count"
  namespace           = "AWS/ApplicationELB"
  period              = 60
  statistic           = "Sum"
  threshold           = 10
  alarm_description   = "Alarm when the number of 5xx errors from the connector ALB exceeds 10 in a 3 minute period"
  dimensions = {
    LoadBalancer = aws_lb.adaptor.name
  }
  treat_missing_data = "notBreaching"
  alarm_actions      = [aws_sns_topic.cloudwatch_alerts.arn]
  ok_actions         = [aws_sns_topic.cloudwatch_alerts.arn]

  tags = local.tags
}

# Alarm for ECS Container Count for Connector Service
resource "aws_cloudwatch_metric_alarm" "container_connector_count" {
  alarm_name          = "${local.application_name}-${local.environment}-connector-container-count-low"
  comparison_operator = "LessThanThreshold"
  evaluation_periods  = 1
  metric_name         = "RunningTaskCount"
  namespace           = "ECS/ContainerInsights"
  period              = 60
  statistic           = "Average"
  threshold           = local.application_data.accounts[local.environment].connector_app_count
  dimensions = {
    ClusterName = aws_ecs_cluster.main.name
    ServiceName = aws_ecs_service.ecs_connector_service.name
  }
  alarm_description         = "The number of OIA ECS tasks is less than ${local.application_data.accounts[local.environment].opa_app_count}. Runbook: https://dsdmoj.atlassian.net/wiki/spaces/CCMS/pages/1408598133/Monitoring+and+Alerts"
  treat_missing_data        = "breaching"
  alarm_actions             = [aws_sns_topic.cloudwatch_alerts.arn]
  ok_actions                = [aws_sns_topic.cloudwatch_alerts.arn]
  insufficient_data_actions = []

  tags = local.tags
}

# Alarm for ECS Container Count for OpaHub Service
resource "aws_cloudwatch_metric_alarm" "container_opahub_count" {
  alarm_name          = "${local.application_name}-${local.environment}-opahub-container-count-low"
  comparison_operator = "LessThanThreshold"
  evaluation_periods  = 1
  metric_name         = "RunningTaskCount"
  namespace           = "ECS/ContainerInsights"
  period              = 60
  statistic           = "Average"
  threshold           = local.application_data.accounts[local.environment].opa_app_count
  dimensions = {
    ClusterName = aws_ecs_cluster.main.name
    ServiceName = aws_ecs_service.opahub.name
  }
  alarm_description         = "The number of OIA ECS tasks is less than ${local.application_data.accounts[local.environment].opa_app_count}. Runbook: https://dsdmoj.atlassian.net/wiki/spaces/CCMS/pages/1408598133/Monitoring+and+Alerts"
  treat_missing_data        = "breaching"
  alarm_actions             = [aws_sns_topic.cloudwatch_alerts.arn]
  ok_actions                = [aws_sns_topic.cloudwatch_alerts.arn]
  insufficient_data_actions = []

  tags = local.tags
}
# Alarm for ECS Container Count for Adaptor Service
resource "aws_cloudwatch_metric_alarm" "container_adaptor_count" {
  alarm_name          = "${local.application_name}-${local.environment}-adaptor-container-count-low"
  comparison_operator = "LessThanThreshold"
  evaluation_periods  = 1
  metric_name         = "RunningTaskCount"
  namespace           = "ECS/ContainerInsights"
  period              = 60
  statistic           = "Average"
  threshold           = local.application_data.accounts[local.environment].adaptor_app_count
  dimensions = {
    ClusterName = aws_ecs_cluster.main.name
    ServiceName = aws_ecs_service.ecs_adaptor_service.name
  }
  alarm_description         = "The number of OIA ECS tasks is less than ${local.application_data.accounts[local.environment].opa_app_count}. Runbook: https://dsdmoj.atlassian.net/wiki/spaces/CCMS/pages/1408598133/Monitoring+and+Alerts"
  treat_missing_data        = "breaching"
  alarm_actions             = [aws_sns_topic.cloudwatch_alerts.arn]
  ok_actions                = [aws_sns_topic.cloudwatch_alerts.arn]
  insufficient_data_actions = []

  tags = local.tags
}

# Underlying EC2 Instance Status Check Failure
resource "aws_cloudwatch_metric_alarm" "Status_Check_Failure" {
  alarm_name          = "${local.application_name}-${local.environment}-status-check-failure"
  alarm_description   = "A oia cluster EC2 instance has failed a status check, Runbook - https://dsdmoj.atlassian.net/wiki/spaces/CCMS/pages/1408598133/Monitoring+and+Alerts"
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

# Alarm for RDS CPU Utilization
resource "aws_cloudwatch_metric_alarm" "oia_rds_cpu_high" {
  alarm_name          = "${local.application_name}-${local.environment}-rds-cpu-high"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "CPUUtilization"
  namespace           = "AWS/RDS"
  period              = 300
  statistic           = "Average"
  threshold           = 80
  dimensions = {
    DBInstanceIdentifier = aws_db_instance.opahub_db.id
  }
  alarm_description = "CPU Utilization for OIA RDS instance is above 80%"

  treat_missing_data = "notBreaching"
  alarm_actions      = [aws_sns_topic.cloudwatch_alerts.arn]
  ok_actions         = [aws_sns_topic.cloudwatch_alerts.arn]

  tags = local.tags
}

# Alarm for RDS Free Storage Space
resource "aws_cloudwatch_metric_alarm" "oia_rds_storage_low" {
  alarm_name          = "${local.application_name}-${local.environment}-rds-storage-low"
  comparison_operator = "LessThanThreshold"
  evaluation_periods  = "5"
  metric_name         = "FreeStorageSpace"
  namespace           = "AWS/RDS"
  period              = "60"
  statistic           = "Average"
  threshold           = 2000000000 # ~2GB
  dimensions = {
    DBInstanceIdentifier = aws_db_instance.opahub_db.id
  }
  alarm_description = "Free storage space for OIA RDS instance is below 2GB"

  treat_missing_data = "notBreaching"
  alarm_actions      = [aws_sns_topic.cloudwatch_alerts.arn]
  ok_actions         = [aws_sns_topic.cloudwatch_alerts.arn]

  tags = local.tags
}

# Alarm for RDS Freeable Memory
resource "aws_cloudwatch_metric_alarm" "oia_rds_freeable_memory_low" {
  alarm_name          = "${local.application_name}-${local.environment}-rds-freeable-memory-low"
  comparison_operator = "LessThanThreshold"
  evaluation_periods  = "5"
  metric_name         = "FreeableMemory"
  namespace           = "AWS/RDS"
  period              = "60"
  statistic           = "Average"
  threshold           = 200000000 # ~200MB
  dimensions = {
    DBInstanceIdentifier = aws_db_instance.opahub_db.id
  }
  alarm_description = "Freeable memory for OIA RDS instance is below 200MB"

  treat_missing_data = "notBreaching"
  alarm_actions      = [aws_sns_topic.cloudwatch_alerts.arn]
  ok_actions         = [aws_sns_topic.cloudwatch_alerts.arn]

  tags = local.tags
}

# Alarm for RDS IOPS Burst Balance
resource "aws_cloudwatch_metric_alarm" "oia_rds_burst_balance_low" {
  alarm_name          = "${local.application_name}-${local.environment}-rds-burst-balance-low"
  comparison_operator = "LessThanThreshold"
  evaluation_periods  = "5"
  metric_name         = "EBSIOBalance%"
  namespace           = "AWS/RDS"
  period              = "60"
  statistic           = "Average"
  threshold           = 20 # ~20%
  dimensions = {
    DBInstanceIdentifier = aws_db_instance.opahub_db.id
  }
  alarm_description = "Alarm when EBS IO credit balance drops below 20% for RDS instance"

  treat_missing_data = "notBreaching"
  alarm_actions      = [aws_sns_topic.cloudwatch_alerts.arn]
  ok_actions         = [aws_sns_topic.cloudwatch_alerts.arn]

  tags = local.tags
}
