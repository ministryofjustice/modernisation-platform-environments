

locals {
  cluster_name = split("/", module.ecs.ecs_cluster_arn)[1]
}

# SNS topic for monitoring to send alarms to
resource "aws_sns_topic" "vcms_alerting" {
  name = "vcms_alerting"
}

# # # # # # # # # # # # # 
#  ECS Cluster Alarms   #
# # # # # # # # # # # # # 

# Alarm for high CPU usage
resource "aws_cloudwatch_metric_alarm" "vcms_cpu_over_threshold" {
  alarm_name          = "vcms-ecs-cpu-threshold"
  alarm_description   = "Triggers alarm if ECS CPU crosses a threshold"
  namespace           = "AWS/ECS"
  metric_name         = "CPUUtilization"
  statistic           = "Average"
  period              = "60"
  evaluation_periods  = "5"
  alarm_actions       = [aws_sns_topic.vcms_alerting.arn]
  ok_actions          = [aws_sns_topic.vcms_alerting.arn]
  threshold           = "80"
  treat_missing_data  = "missing"
  comparison_operator = "GreaterThanThreshold"

  dimensions = {
    ClusterName = local.cluster_name
    ServiceName = "vcms-${local.environment}"
  }

  tags = merge(
    local.tags,
    {
      Name = local.application_name
    }
  )
}

# Alarm for high memory usage
resource "aws_cloudwatch_metric_alarm" "vcms_memory_over_threshold" {
  alarm_name          = "vcms-ecs-memory-threshold"
  alarm_description   = "Triggers alarm if ECS memory crosses a threshold"
  namespace           = "AWS/ECS"
  metric_name         = "MemoryUtilization"
  statistic           = "Average"
  period              = "60"
  evaluation_periods  = "5"
  alarm_actions       = [aws_sns_topic.vcms_alerting.arn]
  ok_actions          = [aws_sns_topic.vcms_alerting.arn]
  threshold           = "80"
  treat_missing_data  = "missing"
  comparison_operator = "GreaterThanThreshold"

  dimensions = {
    ClusterName = local.cluster_name
    ServiceName = "vcms-${local.environment}"
  }

  tags = merge(
    local.tags,
    {
      Name = local.application_name
    }
  )
}


# # # # # # # # # # # # # 
#      RDS Alarms       #
# # # # # # # # # # # # # 

resource "aws_cloudwatch_metric_alarm" "cpu_over_threshold" {
  alarm_name          = "vcms-rds-cpu-threshold"
  alarm_description   = "Triggers alarm if RDS CPU crosses a threshold"
  namespace           = "AWS/RDS"
  metric_name         = "CPUUtilization"
  statistic           = "Average"
  period              = "60"
  evaluation_periods  = "5"
  alarm_actions       = [aws_sns_topic.vcms_alerting.arn]
  ok_actions          = [aws_sns_topic.vcms_alerting.arn]
  threshold           = "80"
  treat_missing_data  = "missing"
  comparison_operator = "GreaterThanThreshold"

  dimensions = {
    DBInstanceIdentifier = "${local.application_name}-${local.environment}-database"
  }

  tags = merge(
    local.tags,
    {
      Name = local.application_name
    }
  )
}

resource "aws_cloudwatch_metric_alarm" "ram_over_threshold" {
  alarm_name          = "vcms-rds-ram-threshold"
  alarm_description   = "Triggers alarm if RDS RAM crosses a threshold"
  namespace           = "AWS/RDS"
  metric_name         = "FreeableMemory"
  statistic           = "Average"
  period              = "60"
  evaluation_periods  = "10"
  alarm_actions       = [aws_sns_topic.vcms_alerting.arn]
  ok_actions          = [aws_sns_topic.vcms_alerting.arn]
  threshold           = "400000000"
  treat_missing_data  = "missing"
  comparison_operator = "LessThanThreshold"

  dimensions = {
    DBInstanceIdentifier = "${local.application_name}-${local.environment}-database"
  }

  tags = merge(
    local.tags,
    {
      Name = local.application_name
    }
  )
}

resource "aws_cloudwatch_metric_alarm" "read_latency_over_threshold" {
  alarm_name          = "vcms-rds-read-latency-threshold"
  alarm_description   = "Triggers alarm if RDS read latency crosses a threshold"
  namespace           = "AWS/RDS"
  metric_name         = "ReadLatency"
  statistic           = "Average"
  period              = "60"
  evaluation_periods  = "5"
  alarm_actions       = [aws_sns_topic.vcms_alerting.arn]
  ok_actions          = [aws_sns_topic.vcms_alerting.arn]
  threshold           = "5"
  treat_missing_data  = "missing"
  comparison_operator = "GreaterThanThreshold"

  dimensions = {
    DBInstanceIdentifier = "${local.application_name}-${local.environment}-database"
  }

  tags = merge(
    local.tags,
    {
      Name = local.application_name
    }
  )
}

resource "aws_cloudwatch_metric_alarm" "write_latency_over_threshold" {
  alarm_name          = "vcms-rds-write-latency-threshold"
  alarm_description   = "Triggers alarm if RDS write latency crosses a threshold"
  namespace           = "AWS/RDS"
  metric_name         = "WriteLatency"
  statistic           = "Average"
  period              = "60"
  evaluation_periods  = "5"
  alarm_actions       = [aws_sns_topic.vcms_alerting.arn]
  ok_actions          = [aws_sns_topic.vcms_alerting.arn]
  threshold           = "5"
  treat_missing_data  = "missing"
  comparison_operator = "GreaterThanThreshold"

  dimensions = {
    DBInstanceIdentifier = "${local.application_name}-${local.environment}-database"
  }

  tags = merge(
    local.tags,
    {
      Name = local.application_name
    }
  )
}

resource "aws_cloudwatch_metric_alarm" "db_connections_over_threshold" {
  alarm_name          = "vcms-rds-db-connections-threshold"
  alarm_description   = "Triggers alarm if RDS database connections crosses a threshold"
  namespace           = "AWS/RDS"
  metric_name         = "DatabaseConnections"
  statistic           = "Average"
  period              = "60"
  evaluation_periods  = "5"
  alarm_actions       = [aws_sns_topic.vcms_alerting.arn]
  ok_actions          = [aws_sns_topic.vcms_alerting.arn]
  threshold           = "100"
  treat_missing_data  = "missing"
  comparison_operator = "GreaterThanThreshold"

  dimensions = {
    DBInstanceIdentifier = "${local.application_name}-${local.environment}-database"
  }

  tags = merge(
    local.tags,
    {
      Name = local.application_name
    }
  )
}

resource "aws_cloudwatch_metric_alarm" "db_queue_depth_over_threshold" {
  alarm_name          = "vcms-rds-db-queue-depth-threshold"
  alarm_description   = "Triggers alarm if RDS database queue depth crosses a threshold"
  namespace           = "AWS/RDS"
  metric_name         = "DiskQueueDepth"
  statistic           = "Average"
  period              = "300"
  evaluation_periods  = "5"
  alarm_actions       = [aws_sns_topic.vcms_alerting.arn]
  ok_actions          = [aws_sns_topic.vcms_alerting.arn]
  threshold           = "60"
  treat_missing_data  = "missing"
  comparison_operator = "GreaterThanThreshold"

  dimensions = {
    DBInstanceIdentifier = "${local.application_name}-${local.environment}-database"
  }

  tags = merge(
    local.tags,
    {
      Name = local.application_name
    }
  )
}



# # # # # # # # # # # # # #
#  Load Balancer Alarms   #
# # # # # # # # # # # # # #


resource "aws_cloudwatch_metric_alarm" "lb_high_5XX_count" {
  alarm_name                = "${local.application_name}-lb-5XX-count--critical"
  comparison_operator       = "GreaterThanOrEqualToThreshold"
  evaluation_periods        = "2"
  metric_name               = "HTTPCode_ELB_5XX_Count"
  namespace                 = "AWS/ApplicationELB"
  period                    = "60"
  statistic                 = "Sum"
  threshold                 = "10"
  alarm_description         = "This alarm monitors lb 5XX count"
  insufficient_data_actions = []
  alarm_actions             = [aws_sns_topic.vcms_alerting.arn]
  ok_actions                = [aws_sns_topic.vcms_alerting.arn]
  treat_missing_data        = "notBreaching"
  dimensions = {
    LoadBalancer = aws_lb.frontend.arn
  }
}

resource "aws_cloudwatch_metric_alarm" "lb_high_4XX_count" {
  alarm_name                = "${local.application_name}-lb-4XX-count--critical"
  comparison_operator       = "GreaterThanOrEqualToThreshold"
  evaluation_periods        = "2"
  metric_name               = "HTTPCode_ELB_4XX_Count"
  namespace                 = "AWS/ApplicationELB"
  period                    = "60"
  statistic                 = "Sum"
  threshold                 = "10"
  alarm_description         = "This alarm monitors lb 4XX count"
  insufficient_data_actions = []
  alarm_actions             = [aws_sns_topic.vcms_alerting.arn]
  ok_actions                = [aws_sns_topic.vcms_alerting.arn]
  treat_missing_data        = "notBreaching"
  dimensions = {
    LoadBalancer = aws_lb.frontend.arn
  }
}

resource "aws_cloudwatch_metric_alarm" "lb_high_target_response_time" {
  alarm_name                = "${local.application_name}-lb-target-response-time--critical"
  comparison_operator       = "GreaterThanOrEqualToThreshold"
  evaluation_periods        = "2"
  metric_name               = "TargetResponseTime"
  namespace                 = "AWS/ApplicationELB"
  period                    = "60"
  statistic                 = "Average"
  threshold                 = "1"
  alarm_description         = "This alarm monitors lb target response time"
  insufficient_data_actions = []
  alarm_actions             = [aws_sns_topic.vcms_alerting.arn]
  ok_actions                = [aws_sns_topic.vcms_alerting.arn]
  treat_missing_data        = "notBreaching"
  dimensions = {
    LoadBalancer = aws_lb.frontend.arn
  }
}

resource "aws_cloudwatch_metric_alarm" "lb_high_unhealthy_host_count" {
  alarm_name                = "${local.application_name}-unhealthy-host-count--critical"
  comparison_operator       = "LessThanOrEqualToThreshold"
  evaluation_periods        = "1"
  metric_name               = "HealthyHostCount"
  namespace                 = "AWS/ApplicationELB"
  period                    = "60"
  statistic                 = "Average"
  threshold                 = "0"
  alarm_description         = "This alarm monitors healthy host count"
  insufficient_data_actions = []
  alarm_actions             = [aws_sns_topic.vcms_alerting.arn]
  ok_actions                = [aws_sns_topic.vcms_alerting.arn]
  treat_missing_data        = "missing"
  dimensions = {
    LoadBalancer = aws_lb.frontend.arn_suffix
    TargetGroup  = aws_lb_target_group.frontend.arn_suffix
  }
}

resource "aws_cloudwatch_metric_alarm" "target_group_high_4XX_error_rate" {
  alarm_name          = "${local.application_name}-target-group-high-4XX-error-rate--critical"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = "3"
  metric_name         = "HTTPCode_Target_4XX_Count"
  namespace           = "AWS/ApplicationELB"
  period              = "60"
  statistic           = "Sum"
  threshold           = "10"
  alarm_description   = "Sum of 4XX error responses returned by targets in target group exceeds 1 in given period"
  alarm_actions       = [aws_sns_topic.vcms_alerting.arn]
  ok_actions          = [aws_sns_topic.vcms_alerting.arn]
  treat_missing_data  = "notBreaching"
  dimensions = {
    LoadBalancer   = aws_lb.frontend.arn_suffix
    TargetGroupArn = aws_lb_target_group.frontend.arn_suffix
  }
}

resource "aws_cloudwatch_metric_alarm" "target_group_high_5XX_error_rate" {
  alarm_name          = "${local.application_name}-target-group-high-5XX-error-rate--critical"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = "3"
  metric_name         = "HTTPCode_Target_5XX_Count"
  namespace           = "AWS/ApplicationELB"
  period              = "60"
  statistic           = "Sum"
  threshold           = "10"
  alarm_description   = "Sum of 5XX error responses returned by targets in target group exceeds 1 in given period"
  alarm_actions       = [aws_sns_topic.vcms_alerting.arn]
  ok_actions          = [aws_sns_topic.vcms_alerting.arn]
  treat_missing_data  = "notBreaching"
  dimensions = {
    LoadBalancer   = aws_lb.frontend.arn
    TargetGroupArn = aws_lb_target_group.frontend.arn
  }
}



