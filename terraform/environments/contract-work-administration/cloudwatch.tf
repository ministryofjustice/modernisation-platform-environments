resource "aws_cloudwatch_metric_alarm" "efs_data_write" {

  alarm_name          = "${local.application_name_short}-${local.environment}-efs-data-write"
  alarm_description   = "EFS Data Write IO Too High"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  dimensions = {
    FileSystemId = aws_efs_file_system.cwa.id
  }
  evaluation_periods = "5"
  metric_name        = "DataWriteIOBytes"
  namespace          = "AWS/EFS"
  period             = "60"
  statistic          = "Average"
  threshold          = "1100000"
#   alarm_actions      = [aws_sns_topic.alerting_topic.arn]
#   ok_actions         = [aws_sns_topic.alerting_topic.arn]
  treat_missing_data = "ignore"
  tags = merge(
    local.tags,
    {
      Name = "${local.application_name_short}-${local.environment}-efs-data-write"
    }
  )
}

resource "aws_cloudwatch_metric_alarm" "efs_data_read" {

  alarm_name          = "${local.application_name_short}-${local.environment}-efs-data-read"
  alarm_description   = "EFS Data Read IO Too High"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  dimensions = {
    FileSystemId = aws_efs_file_system.cwa.id
  }
  evaluation_periods = "5"
  metric_name        = "DataReadIOBytes"
  namespace          = "AWS/EFS"
  period             = "60"
  statistic          = "Average"
  threshold          = "1100000"
#   alarm_actions      = [aws_sns_topic.alerting_topic.arn]
#   ok_actions         = [aws_sns_topic.alerting_topic.arn]
  treat_missing_data = "ignore"
  tags = merge(
    local.tags,
    {
      Name = "${local.application_name_short}-${local.environment}-efs-data-read"
    }
  )
}

resource "aws_cloudwatch_metric_alarm" "database_cpu" {

  alarm_name          = "${local.application_name_short}-${local.environment}-database-ec2-cpu-alarm"
  alarm_description   = "The average CPU utilization is too high for the database instance"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  dimensions = {
    InstanceId = aws_instance.database.id
  }
  evaluation_periods = "5"
  metric_name        = "CPUUtilization"
  namespace          = "AWS/EC2"
  period             = "60"
  statistic          = "Average"
  threshold          = "95"
#   alarm_actions      = [aws_sns_topic.alerting_topic.arn]
#   ok_actions         = [aws_sns_topic.alerting_topic.arn]
#   treat_missing_data = "ignore"
  tags = merge(
    local.tags,
    {
      Name = "${local.application_name_short}-${local.environment}-database-ec2-cpu-alarm"
    }
  )
}

resource "aws_cloudwatch_metric_alarm" "elb_latency" {

  alarm_name          = "${local.application_name_short}-${local.environment}-elb-latency"
  alarm_description   = "ELB Latency Too High"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  dimensions = {
    AvailabilityZone = "eu-west-2a"
  }
  evaluation_periods = "5"
  metric_name        = "Latency"
  namespace          = "AWS/ELB"
  period             = "60"
  statistic          = "Average"
  threshold          = "1"
#   alarm_actions      = [aws_sns_topic.alerting_topic.arn]
#   ok_actions         = [aws_sns_topic.alerting_topic.arn]
#   treat_missing_data = ""
  tags = merge(
    local.tags,
    {
      Name = "${local.application_name_short}-${local.environment}-elb-latency"
    }
  )
}

resource "aws_cloudwatch_metric_alarm" "elb_request_count" {

  alarm_name          = "${local.application_name_short}-${local.environment}-elb-request-count"
  alarm_description   = "ELB Request Count Too High"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  dimensions = {
    AvailabilityZone = "eu-west-2a"
  }
  evaluation_periods = "5"
  metric_name        = "RequestCount"
  namespace          = "AWS/ELB"
  period             = "60"
  statistic          = "Sum"
  threshold          = "1000"
#   alarm_actions      = [aws_sns_topic.alerting_topic.arn]
#   ok_actions         = [aws_sns_topic.alerting_topic.arn]
#   treat_missing_data = ""
  tags = merge(
    local.tags,
    {
      Name = "${local.application_name_short}-${local.environment}-elb-request-count"
    }
  )
}

resource "aws_cloudwatch_metric_alarm" "app1_ec2_status_check" {

  alarm_name          = "${local.application_name_short}-${local.environment}-app1-ec2-status-check"
  alarm_description   = "App1 EC2 Instance Status Check Failed"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  dimensions = {
    InstanceId = aws_instance.app1.id
  }
  evaluation_periods = "5"
  metric_name        = "StatusCheckFailed"
  namespace          = "AWS/EC2"
  period             = "60"
  statistic          = "Sum"
  threshold          = "1"
#   alarm_actions      = [aws_sns_topic.alerting_topic.arn]
#   ok_actions         = [aws_sns_topic.alerting_topic.arn]
#   treat_missing_data = ""
  tags = merge(
    local.tags,
    {
      Name = "${local.application_name_short}-${local.environment}-app-ec2-status-check"
    }
  )
}

resource "aws_cloudwatch_metric_alarm" "app2_ec2_status_check" {
  count = contains(["development", "testing"], local.environment) ? 0 : 1
  alarm_name          = "${local.application_name_short}-${local.environment}-app2-ec2-status-check"
  alarm_description   = "App2 EC2 Instance Status Check Failed"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  dimensions = {
    InstanceId = aws_instance.app2[0].id
  }
  evaluation_periods = "5"
  metric_name        = "StatusCheckFailed_Instance"
  namespace          = "AWS/EC2"
  period             = "60"
  statistic          = "Sum"
  threshold          = "1"
#   alarm_actions      = [aws_sns_topic.alerting_topic.arn]
#   ok_actions         = [aws_sns_topic.alerting_topic.arn]
#   treat_missing_data = ""
  tags = merge(
    local.tags,
    {
      Name = "${local.application_name_short}-${local.environment}-app-ec2-status-check"
    }
  )
}

resource "aws_cloudwatch_metric_alarm" "cm_ec2_status_check" {

  alarm_name          = "${local.application_name_short}-${local.environment}-concurrent-manager-ec2-status-check"
  alarm_description   = "Concurrent Manager EC2 Instance Status Check Failed"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  dimensions = {
    InstanceId = aws_instance.concurrent_manager.id
  }
  evaluation_periods = "5"
  metric_name        = "StatusCheckFailed"
  namespace          = "AWS/EC2"
  period             = "60"
  statistic          = "Sum"
  threshold          = "1"
#   alarm_actions      = [aws_sns_topic.alerting_topic.arn]
#   ok_actions         = [aws_sns_topic.alerting_topic.arn]
#   treat_missing_data = ""
  tags = merge(
    local.tags,
    {
      Name = "${local.application_name_short}-${local.environment}-concurrent-manager-ec2-status-check"
    }
  )
}

resource "aws_cloudwatch_metric_alarm" "database_ec2_status_check" {

  alarm_name          = "${local.application_name_short}-${local.environment}-database-ec2-status-check"
  alarm_description   = "Database EC2 Instance Status Check Failed"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  dimensions = {
    InstanceId = aws_instance.database.id
  }
  evaluation_periods = "5"
  metric_name        = "StatusCheckFailed"
  namespace          = "AWS/EC2"
  period             = "60"
  statistic          = "Sum"
  threshold          = "1"
#   alarm_actions      = [aws_sns_topic.alerting_topic.arn]
#   ok_actions         = [aws_sns_topic.alerting_topic.arn]
#   treat_missing_data = ""
  tags = merge(
    local.tags,
    {
      Name = "${local.application_name_short}-${local.environment}-database-ec2-status-check"
    }
  )
}


resource "aws_cloudwatch_metric_alarm" "database_ec2_read_ops" {

  alarm_name          = "${local.application_name_short}-${local.environment}-database-ec2-read-ops"
  alarm_description   = "EC2 Data Read Ops Too High"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  dimensions = {
    InstanceId = aws_instance.database.id
  }
  evaluation_periods = "5"
  metric_name        = "DiskReadOps"
  namespace          = "AWS/EC2"
  period             = "60"
  statistic          = "Average"
  threshold          = "1100000"
#   alarm_actions      = [aws_sns_topic.alerting_topic.arn]
#   ok_actions         = [aws_sns_topic.alerting_topic.arn]
  treat_missing_data = "ignore"
  tags = merge(
    local.tags,
    {
      Name = "${local.application_name_short}-${local.environment}-database-ec2-read-ops"
    }
  )
}

resource "aws_cloudwatch_metric_alarm" "database_ec2_write_ops" {

  alarm_name          = "${local.application_name_short}-${local.environment}-database-ec2-write-ops"
  alarm_description   = "EC2 Data Write Ops Too High"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  dimensions = {
    InstanceId = aws_instance.database.id
  }
  evaluation_periods = "5"
  metric_name        = "DiskWriteOps"
  namespace          = "AWS/EC2"
  period             = "60"
  statistic          = "Average"
  threshold          = "1100000"
#   alarm_actions      = [aws_sns_topic.alerting_topic.arn]
#   ok_actions         = [aws_sns_topic.alerting_topic.arn]
  treat_missing_data = "ignore"
  tags = merge(
    local.tags,
    {
      Name = "${local.application_name_short}-${local.environment}-database-ec2-write-ops"
    }
  )
}


resource "aws_cloudwatch_metric_alarm" "database_ec2_swap" {

  alarm_name          = "${local.application_name_short}-${local.environment}-database-ec2-swap"
  alarm_description   = "Database EC2 Instance Swap Used Too High"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  dimensions = {
    InstanceId = aws_instance.database.id
  }
  evaluation_periods = "5"
  metric_name        = "SwapUsed"
  namespace          = "System/Linux"
  period             = "60"
  statistic          = "Average"
  threshold          = "50"
#   alarm_actions      = [aws_sns_topic.alerting_topic.arn]
#   ok_actions         = [aws_sns_topic.alerting_topic.arn]
#   treat_missing_data = ""
  tags = merge(
    local.tags,
    {
      Name = "${local.application_name_short}-${local.environment}-database-ec2-swap"
    }
  )
}

# resource "aws_cloudwatch_metric_alarm" "" {

#   alarm_name          = "${local.application_name_short}-${local.environment}-"
#   alarm_description   = ""
#   comparison_operator = ""
#   dimensions = {
#     InstanceId = aws_instance.database.id
#   }
#   evaluation_periods = ""
#   metric_name        = ""
#   namespace          = ""
#   period             = ""
#   statistic          = ""
#   threshold          = ""
# #   alarm_actions      = [aws_sns_topic.alerting_topic.arn]
# #   ok_actions         = [aws_sns_topic.alerting_topic.arn]
#   treat_missing_data = ""
#   tags = merge(
#     local.tags,
#     {
#       Name = "${local.application_name_short}-${local.environment}-"
#     }
#   )
# }