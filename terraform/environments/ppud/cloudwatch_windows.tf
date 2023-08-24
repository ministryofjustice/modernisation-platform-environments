# =====================
# Alerts - EC2 Windows
# =====================

# Create a data source to fetch the tags of each instance
data "aws_instances" "windows_tagged_instances" {
  filter {
     name = "tag:patch_group"
     values = ["prod_win_patch"]
  }
}

# Disk Free Alarm
resource "aws_cloudwatch_metric_alarm" "high_disk_usage" {
  for_each            = toset(data.aws_instances.windows_tagged_instances.ids)
  alarm_name          = "high-disk-usage-${each.key}"
  comparison_operator = "LessThanOrEqualToThreshold"
  evaluation_periods  = "3"
  datapoints_to_alarm = "2"
  metric_name         = "LogicalDisk % Free Space"
  namespace           = "CWAgent"
  period              = "60"
  statistic           = "Average"
  threshold           = "5"
  treat_missing_data  = "notBreaching"
  alarm_description   = "This metric monitors the amount of free disk space on the instance. If the amount of free disk space falls below 5% for 2 minutes, the alarm will trigger"
  alarm_actions       = [aws_sns_topic.cw_alerts[0].arn]
  dimensions = {
    InstanceId = each.key
  }
}

# Low Available Memory Alarm

resource "aws_cloudwatch_metric_alarm" "Memory_percentage_Committed_Bytes_In_Use" {
  for_each            = toset(data.aws_instances.windows_tagged_instances.ids)
  alarm_name          = "Memory-percentage-Committed-Bytes-In-Use-${each.key}"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = "15"
  datapoints_to_alarm = "15"
  metric_name         = "Memory % Committed Bytes In Use"
  namespace           = "CWAgent"
  period              = "60"
  statistic           = "Maximum"
  threshold           = "90"
  treat_missing_data  = "notBreaching"
  alarm_description   = "Triggers if memory usage is continually high for 15 minutes"
  alarm_actions       = [aws_sns_topic.cw_alerts[0].arn]
    dimensions = {
    InstanceId = each.key
  }
}


# High CPU IOwait Alarm
resource "aws_cloudwatch_metric_alarm" "cpu_usage_iowait" {
  for_each            = toset(data.aws_instances.windows_tagged_instances.ids)
  alarm_name          = "cpu-usage-iowait-${each.key}"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = "6"
  datapoints_to_alarm = "5"
  metric_name         = "cpu_usage_iowait"
  treat_missing_data  = "notBreaching"
  namespace           = "CWAgent"
  period              = "60"
  statistic           = "Average"
  threshold           = "90"
  alarm_description   = "This metric monitors the amount of CPU time spent waiting for I/O to complete. If the average CPU time spent waiting for I/O to complete is greater than 90% for 30 minutes, the alarm will trigger."
  alarm_actions       = [aws_sns_topic.cw_alerts[0].arn]
  dimensions = { 
    InstanceId = each.key
  }
}

# CPU Utilization Alarm
resource "aws_cloudwatch_metric_alarm" "cpu" {
  for_each            = toset(data.aws_instances.windows_tagged_instances.ids)
  alarm_name          = "CPU-High-${each.key}"    # name of the alarm
  comparison_operator = "GreaterThanOrEqualToThreshold"   # threshold to trigger the alarm state
  period              = "60"                              # period in seconds over which the specified statistic is applied
  threshold           = "90"                              # threshold for the alarm - see comparison_operator for usage
  evaluation_periods  = "3"                               # how many periods over which to evaluate the alarm
  datapoints_to_alarm = "2"                               # how many datapoints must be breaching the threshold to trigger the alarm
  metric_name         = "CPUUtilization"                  # name of the alarm's associated metric
  treat_missing_data  = "notBreaching"
  namespace           = "AWS/EC2"                         # namespace of the alarm's associated metric
  statistic           = "Average"                         # could be Average/Minimum/Maximum etc.
  alarm_description   = "Monitors ec2 cpu utilisation"
  alarm_actions       = [aws_sns_topic.cw_alerts[0].arn]
  dimensions = { 
    InstanceId = each.key
  }
}

# ======================
# EC2 Instance Statuses
# ======================

# Instance Health Alarm
resource "aws_cloudwatch_metric_alarm" "instance_health_check" {
  for_each            = toset(data.aws_instances.windows_tagged_instances.ids)
  alarm_name          = "instance-health-check-failed-${each.key}"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = "3"
  datapoints_to_alarm = "2"
  metric_name         = "StatusCheckFailed_Instance"
  namespace           = "AWS/EC2"
  period              = "60"
  statistic           = "Average"
  threshold           = "1"
  treat_missing_data  = "notBreaching"
  alarm_description   = "Instance status checks monitor the software and network configuration of your individual instance. When an instance status check fails, you typically must address the problem yourself: https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/monitoring-system-instance-status-check.html"
  alarm_actions       = [aws_sns_topic.cw_alerts[0].arn]
  dimensions = { 
    InstanceId = each.key
  }
}

# Status Check Alarm
resource "aws_cloudwatch_metric_alarm" "system_health_check" {
  for_each            = toset(data.aws_instances.windows_tagged_instances.ids)
  alarm_name          = "system-health-check-failed-${each.key}"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = "3"
  datapoints_to_alarm = "2"
  metric_name         = "StatusCheckFailed_System"
  namespace           = "AWS/EC2"
  period              = "60"
  statistic           = "Average"
  threshold           = "1"
  treat_missing_data  = "notBreaching"
  alarm_description   = "System status checks monitor the AWS systems on which your instance runs. These checks detect underlying problems with your instance that require AWS involvement to repair: https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/monitoring-system-instance-status-check.html"
  alarm_actions       = [aws_sns_topic.cw_alerts[0].arn]
  dimensions = { 
    InstanceId = each.key
  }
}


# ====================
# IIS and Event Logs
# ====================

# Status Check Alarm
resource "aws_cloudwatch_metric_alarm" "Windows_IIS_check" {
  for_each            = toset(data.aws_instances.windows_tagged_instances.ids)
  alarm_name          = "IIS-failure-${each.key}"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = "3"
  datapoints_to_alarm = "2"
  metric_name         = "IncomingLogEvents"
  namespace           = "AWS/Logs"
  period              = "60"
  statistic           = "Average"
  threshold           = "1"
  treat_missing_data  = "notBreaching"
  alarm_description   = "System status checks monitor the AWS systems on which your instance runs. These checks detect underlying problems with your instance that require AWS involvement to repair: https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/monitoring-system-instance-status-check.html"
  alarm_actions       = [aws_sns_topic.cw_alerts[0].arn]
  dimensions = { 
    InstanceId = each.key
  }
}

#Log Groups

resource "aws_cloudwatch_log_group" "IIS-Logs" {
count  = local.is-production == true ? 1 : 0
  name = "IIS-Logs"
  retention_in_days = 365
}

resource "aws_cloudwatch_log_group" "System-Event-Logs" {
count  = local.is-production == true ? 1 : 0
  name = "System-Event-Logs"
  retention_in_days = 365
}

resource "aws_cloudwatch_log_group" "Application-Event-Logs" {
count  = local.is-production == true ? 1 : 0
  name = "Application-Event-Logs"
  retention_in_days = 365
}

resource "aws_cloudwatch_log_group" "Windows-Services-Logs" {
count  = local.is-production == true ? 1 : 0
  name = "Windows-Services-Logs"
  retention_in_days = 365
}

resource "aws_cloudwatch_log_group" "Network-Connectivity-Logs" {
count  = local.is-production == true ? 1 : 0
  name = "Network-Connectivity-Logs"
  retention_in_days = 365
}

resource "aws_cloudwatch_log_group" "SQL-Error-Logs" {
count  = local.is-production == true ? 1 : 0
  name = "SQL-Error-Logs"
  retention_in_days = 365
}

#Metric Filters

resource "aws_cloudwatch_log_metric_filter" "ServiceStatus-Running" {
count  = local.is-production == true ? 1 : 0
  name           = "ServiceStatus-Running"
  log_group_name = aws_cloudwatch_log_group.Windows-Services-Logs[count.index].name
  pattern        = "[date, time, Instance, Service, status=Running]"
  metric_transformation {
    name      = "IsRunning"
    namespace = "ServiceStatus"
    value     = "1"
    dimensions = {
      Instance = "$Instance"
      Service = "$Service"
    }
  }
}

resource "aws_cloudwatch_log_metric_filter" "ServiceStatus-NotRunning" {
count  = local.is-production == true ? 1 : 0
  name           = "ServiceStatus-NotRunning"
  log_group_name = aws_cloudwatch_log_group.Windows-Services-Logs[count.index].name
  pattern        = "[date, time, Instance, Service, status!=Running]"
  metric_transformation {
    name      = "IsRunning"
    namespace = "ServiceStatus"
    value     = "0"
    dimensions = {
      Instance = "$Instance"
      Service = "$Service"
    }
  }
}

resource "aws_cloudwatch_log_metric_filter" "PortStatus-True" {
count  = local.is-production == true ? 1 : 0
  name           = "PortStatus-True"
  log_group_name = aws_cloudwatch_log_group.Network-Connectivity-Logs[count.index].name
  pattern        = "[date, time, Instance, Port, status=True]"
  metric_transformation {
    name      = "True"
    namespace = "PortStatus"
    value     = "1"
    dimensions = {
      Instance = "$Instance"
      Port = "$Port"
    }
  }
}

resource "aws_cloudwatch_log_metric_filter" "PortStatus-False" {
count  = local.is-production == true ? 1 : 0
  name           = "PortStatus-False"
  log_group_name = aws_cloudwatch_log_group.Network-Connectivity-Logs[count.index].name
  pattern        = "[date, time, Instance, Port, status=False]"
  metric_transformation {
    name      = "False"
    namespace = "PortStatus"
    value     = "0"
    dimensions = {
      Instance = "$Instance"
      Port = "$Port"
    }
  }
}

resource "aws_cloudwatch_log_metric_filter" "SQL-Backup-Failure" {
count  = local.is-production == true ? 1 : 0
  name           = "SQL-Backup-Failure"
  log_group_name = aws_cloudwatch_log_group.SQL-Error-Logs[count.index].name
  pattern        = "Backup failed"
  metric_transformation {
    name      = "Failure"
    namespace = "SQLBackup"
    value     = "1"
  }
}

resource "aws_cloudwatch_log_metric_filter" "SQL-Backup-Success" {
count  = local.is-production == true ? 1 : 0
  name           = "SQL-Backup-Success"
  log_group_name = aws_cloudwatch_log_group.SQL-Error-Logs[count.index].name
  pattern        = "Database backed up. Database: PPUD_LIVE"
  metric_transformation {
    name      = "Success"
    namespace = "SQLBackup"
    value     = "1"
  }
}
