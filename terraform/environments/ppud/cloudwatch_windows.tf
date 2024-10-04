# =====================
# Alerts - EC2 Windows
# =====================

# Create a data source to fetch the tags of each instance
data "aws_instances" "windows_tagged_instances" {
  filter {
    name   = "tag:patch_group"
    values = ["prod_win_patch"]
  }
}


data "aws_instance" "each_ec2" {
  for_each    = toset(data.aws_instances.all_ec2.ids)
  instance_id = each.key
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

# Low Disk Alarm for all Windows instances with C Volumes

resource "aws_cloudwatch_metric_alarm" "low_disk_space_C_volume" {
  for_each            = toset(data.aws_instances.windows_tagged_instances.ids)
  alarm_name          = "Low-Disk-Space-C-Volume-${each.key}"
  comparison_operator = "LessThanOrEqualToThreshold"
  evaluation_periods  = "5"
  datapoints_to_alarm = "5"
  metric_name         = "LogicalDisk % Free Space"
  namespace           = "CWAgent"
  period              = "60"
  statistic           = "Average"
  threshold           = "5"
  treat_missing_data  = "notBreaching"
  alarm_description   = "This metric monitors the amount of free disk space on the instance. If the amount of free disk space falls below 5% for 5 minutes, the alarm will trigger"
  alarm_actions       = [aws_sns_topic.cw_alerts[0].arn]
  dimensions = {
    InstanceId = each.key
    instance   = "C:"
    ImageId    = data.aws_instances.each_ec2[each.key].ami
    InstanceType = data.aws_instances.each_ec2[each.key].instance_type
    objectname = "LogicalDisk"
  }
}

# Low Disk Alarm for all Windows instances with D Volumes

resource "aws_cloudwatch_metric_alarm" "low_disk_space_D_volume" {
  for_each            = toset(data.aws_instances.windows_tagged_instances.ids)
  alarm_name          = "Low-Disk-Space-D-Volume-${each.key}"
  comparison_operator = "LessThanOrEqualToThreshold"
  evaluation_periods  = "5"
  datapoints_to_alarm = "5"
  metric_name         = "LogicalDisk % Free Space"
  namespace           = "CWAgent"
  period              = "60"
  statistic           = "Average"
  threshold           = "5"
  treat_missing_data  = "notBreaching"
  alarm_description   = "This metric monitors the amount of free disk space on the instance. If the amount of free disk space falls below 5% for 5 minutes, the alarm will trigger"
  alarm_actions       = [aws_sns_topic.cw_alerts[0].arn]
  dimensions = {
    InstanceId = each.key
    instance   = "D:"
    ImageId    = data.aws_instances.each_ec2[each.key].ami
    InstanceType = data.aws_instances.each_ec2[each.key].instance_type
    objectname = "LogicalDisk"
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
  alarm_name          = "CPU-High-${each.key}"          # name of the alarm
  comparison_operator = "GreaterThanOrEqualToThreshold" # threshold to trigger the alarm state
  period              = "60"                            # period in seconds over which the specified statistic is applied
  threshold           = "90"                            # threshold for the alarm - see comparison_operator for usage
  evaluation_periods  = "3"                             # how many periods over which to evaluate the alarm
  datapoints_to_alarm = "2"                             # how many datapoints must be breaching the threshold to trigger the alarm
  metric_name         = "CPUUtilization"                # name of the alarm's associated metric
  treat_missing_data  = "notBreaching"
  namespace           = "AWS/EC2" # namespace of the alarm's associated metric
  statistic           = "Average" # could be Average/Minimum/Maximum etc.
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
  count             = local.is-production == true ? 1 : 0
  name              = "IIS-Logs"
  retention_in_days = 365
}

resource "aws_cloudwatch_log_group" "System-Event-Logs" {
  count             = local.is-production == true ? 1 : 0
  name              = "System-Event-Logs"
  retention_in_days = 365
}

resource "aws_cloudwatch_log_group" "Application-Event-Logs" {
  count             = local.is-production == true ? 1 : 0
  name              = "Application-Event-Logs"
  retention_in_days = 365
}

resource "aws_cloudwatch_log_group" "Windows-Services-Logs" {
  count             = local.is-production == true ? 1 : 0
  name              = "Windows-Services-Logs"
  retention_in_days = 365
}

resource "aws_cloudwatch_log_group" "Network-Connectivity-Logs" {
  count             = local.is-production == true ? 1 : 0
  name              = "Network-Connectivity-Logs"
  retention_in_days = 365
}

resource "aws_cloudwatch_log_group" "SQL-Server-Logs" {
  count             = local.is-production == true ? 1 : 0
  name              = "SQL-Server-Logs"
  retention_in_days = 365
}

resource "aws_cloudwatch_log_group" "Windows-Defender-Logs" {
  count             = local.is-production == true ? 1 : 0
  name              = "Windows-Defender-Logs"
  retention_in_days = 365
}

#Metric Filters

resource "aws_cloudwatch_log_metric_filter" "ServiceStatus-Running" {
  count          = local.is-production == true ? 1 : 0
  name           = "ServiceStatus-Running"
  log_group_name = aws_cloudwatch_log_group.Windows-Services-Logs[count.index].name
  pattern        = "[date, time, Instance, Service, status=Running]"
  metric_transformation {
    name      = "IsRunning"
    namespace = "ServiceStatus"
    value     = "1"
    dimensions = {
      Instance = "$Instance"
      Service  = "$Service"
    }
  }
}

resource "aws_cloudwatch_log_metric_filter" "ServiceStatus-NotRunning" {
  count          = local.is-production == true ? 1 : 0
  name           = "ServiceStatus-NotRunning"
  log_group_name = aws_cloudwatch_log_group.Windows-Services-Logs[count.index].name
  pattern        = "[date, time, Instance, Service, status!=Running]"
  metric_transformation {
    name      = "IsRunning"
    namespace = "ServiceStatus"
    value     = "0"
    dimensions = {
      Instance = "$Instance"
      Service  = "$Service"
    }
  }
}

resource "aws_cloudwatch_log_metric_filter" "PortStatus-True" {
  count          = local.is-production == true ? 1 : 0
  name           = "PortStatus-True"
  log_group_name = aws_cloudwatch_log_group.Network-Connectivity-Logs[count.index].name
  pattern        = "[date, time, Instance, Port, status=True]"
  metric_transformation {
    name      = "True"
    namespace = "PortStatus"
    value     = "1"
    dimensions = {
      Instance = "$Instance"
      Port     = "$Port"
    }
  }
}

resource "aws_cloudwatch_log_metric_filter" "PortStatus-False" {
  count          = local.is-production == true ? 1 : 0
  name           = "PortStatus-False"
  log_group_name = aws_cloudwatch_log_group.Network-Connectivity-Logs[count.index].name
  pattern        = "[date, time, Instance, Port, status=False]"
  metric_transformation {
    name      = "False"
    namespace = "PortStatus"
    value     = "0"
    dimensions = {
      Instance = "$Instance"
      Port     = "$Port"
    }
  }
}

resource "aws_cloudwatch_log_metric_filter" "SQLBackupStatus-Successful" {
  count          = local.is-production == true ? 1 : 0
  name           = "SQLBackupStatus-Successful"
  log_group_name = aws_cloudwatch_log_group.SQL-Server-Logs[count.index].name
  pattern        = "[date, time, Instance, SQLBackup, status=Successful]"
  metric_transformation {
    name      = "Successful"
    namespace = "SQLBackupStatus"
    value     = "1"
    dimensions = {
      Instance = "$Instance"
    }
  }
}

resource "aws_cloudwatch_log_metric_filter" "SQLBackupStatus-Failed" {
  count          = local.is-production == true ? 1 : 0
  name           = "SQLBackupStatus-Failed"
  log_group_name = aws_cloudwatch_log_group.SQL-Server-Logs[count.index].name
  pattern        = "[date, time, Instance, SQLBackup, status=Failed]"
  metric_transformation {
    name      = "Failed"
    namespace = "SQLBackupStatus"
    value     = "0"
    dimensions = {
      Instance = "$Instance"
    }
  }
}

# Windows Defender Event Metrics

resource "aws_cloudwatch_log_metric_filter" "MalwareScanStarted" {
  count          = local.is-production == true ? 1 : 0
  name           = "MalwareScanStarted"
  log_group_name = aws_cloudwatch_log_group.Windows-Defender-Logs[count.index].name
  pattern        = "[date, time, Instance, MalwareScanStarted, status=1000]"
  metric_transformation {
    name      = "MalwareScanStarted"
    namespace = "WindowsDefender"
    value     = "1"
    dimensions = {
      Instance           = "$Instance"
      MalwareScanStarted = "$MalwareScanStarted"
    }
  }
}

resource "aws_cloudwatch_log_metric_filter" "MalwareScanFinished" {
  count          = local.is-production == true ? 1 : 0
  name           = "MalwareScanFinished"
  log_group_name = aws_cloudwatch_log_group.Windows-Defender-Logs[count.index].name
  pattern        = "[date, time, Instance, MalwareScanFinished, status=1001]"
  metric_transformation {
    name      = "MalwareScanFinished"
    namespace = "WindowsDefender"
    value     = "1"
    dimensions = {
      Instance            = "$Instance"
      MalwareScanFinished = "$MalwareScanFinished"
    }
  }
}

resource "aws_cloudwatch_log_metric_filter" "MalwareScanStopped" {
  count          = local.is-production == true ? 1 : 0
  name           = "MalwareScanStopped"
  log_group_name = aws_cloudwatch_log_group.Windows-Defender-Logs[count.index].name
  pattern        = "[date, time, Instance, MalwareScanStopped, status=1002]"
  metric_transformation {
    name      = "MalwareScanStopped"
    namespace = "WindowsDefender"
    value     = "1"
    dimensions = {
      Instance           = "$Instance"
      MalwareScanStopped = "$MalwareScanStopped"
    }
  }
}

resource "aws_cloudwatch_log_metric_filter" "MalwareScanFailed" {
  count          = local.is-production == true ? 1 : 0
  name           = "MalwareScanFailed"
  log_group_name = aws_cloudwatch_log_group.Windows-Defender-Logs[count.index].name
  pattern        = "[date, time, Instance, MalwareScanFailed, status=1005]"
  metric_transformation {
    name      = "MalwareScanFailed"
    namespace = "WindowsDefender"
    value     = "1"
    dimensions = {
      Instance          = "$Instance"
      MalwareScanFailed = "$MalwareScanFailed"
    }
  }
}

resource "aws_cloudwatch_log_metric_filter" "MalwareBehaviorDetected" {
  count          = local.is-production == true ? 1 : 0
  name           = "MalwareBehaviorDetected"
  log_group_name = aws_cloudwatch_log_group.Windows-Defender-Logs[count.index].name
  pattern        = "[date, time, Instance, MalwareBehaviorDetected, status=1015]"
  metric_transformation {
    name      = "MalwareBehaviorDetected"
    namespace = "WindowsDefender"
    value     = "1"
    dimensions = {
      Instance                = "$Instance"
      MalwareBehaviorDetected = "$MalwareBehaviorDetected"
    }
  }
}

resource "aws_cloudwatch_log_metric_filter" "MalwareStateDetected" {
  count          = local.is-production == true ? 1 : 0
  name           = "MalwareStateDetected"
  log_group_name = aws_cloudwatch_log_group.Windows-Defender-Logs[count.index].name
  pattern        = "[date, time, Instance, MalwareStateDetected, status=1116]"
  metric_transformation {
    name      = "MalwareStateDetected"
    namespace = "WindowsDefender"
    value     = "1"
    dimensions = {
      Instance             = "$Instance"
      MalwareStateDetected = "$MalwareStateDetected"
    }
  }
}

resource "aws_cloudwatch_log_metric_filter" "MalwareSignatureFailed" {
  count          = local.is-production == true ? 1 : 0
  name           = "MalwareSignatureFailed"
  log_group_name = aws_cloudwatch_log_group.Windows-Defender-Logs[count.index].name
  pattern        = "[date, time, Instance, MalwareSignatureFailed, status=2001]"
  metric_transformation {
    name      = "MalwareSignatureFailed"
    namespace = "WindowsDefender"
    value     = "1"
    dimensions = {
      Instance               = "$Instance"
      MalwareSignatureFailed = "$MalwareSignatureFailed"
    }
  }
}

resource "aws_cloudwatch_log_metric_filter" "MalwareEngineFailed" {
  count          = local.is-production == true ? 1 : 0
  name           = "MalwareEngineFailed"
  log_group_name = aws_cloudwatch_log_group.Windows-Defender-Logs[count.index].name
  pattern        = "[date, time, Instance, MalwareEngineFailed, status=2003]"
  metric_transformation {
    name      = "MalwareEngineFailed"
    namespace = "WindowsDefender"
    value     = "1"
    dimensions = {
      Instance            = "$Instance"
      MalwareEngineFailed = "$MalwareEngineFailed"
    }
  }
}

resource "aws_cloudwatch_log_metric_filter" "MalwareEngineOutofDate" {
  count          = local.is-production == true ? 1 : 0
  name           = "MalwareEngineOutofDate"
  log_group_name = aws_cloudwatch_log_group.Windows-Defender-Logs[count.index].name
  pattern        = "[date, time, Instance, MalwareEngineOutofDate, status=2005]"
  metric_transformation {
    name      = "MalwareEngineOutofDate"
    namespace = "WindowsDefender"
    value     = "1"
    dimensions = {
      Instance               = "$Instance"
      MalwareEngineOutofDate = "$MalwareEngineOutofDate"
    }
  }
}