# ==============================================================================
# Alerts - WINDOWS
# ==============================================================================

# Remote Desktop Services - Windows
# CPU Idle Time - Windows

# Low Available Memory Alarm - Windows
resource "aws_cloudwatch_metric_alarm" "low_available_memory_windows" {
  alarm_name          = "low_available_memory_windows"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = "2"
  datapoints_to_alarm = "2"
  metric_name         = "COMMITTED_BYTES_IN_USE"
  namespace           = "CWAgent"
  period              = "60"
  statistic           = "Average"
  threshold           = "80"
  alarm_description   = "This metric monitors the amount of available memory. If Committed Bytes in Use is > 80% for 2 minutes, the alarm will trigger."
  alarm_actions       = [aws_sns_topic.nomis_alarms.arn]
  tags = {
    Name = "low_available_memory_windows"
  }
}



# High CPU - Windows
resource "aws_cloudwatch_metric_alarm" "high_cpu_windows" {
  alarm_name          = "high_cpu_windows"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = "5"
  datapoints_to_alarm = "5"
  metric_name         = "PROCESSOR_TIME"
  namespace           = "CWAgent"
  period              = "60"
  statistic           = "Average"
  threshold           = "95"
  alarm_description   = "This metric monitors the Processor time. If the Processor time is greater than 95% for 5 minutes, the alarm will trigger: "
  alarm_actions       = [aws_sns_topic.nomis_alarms.arn]
  tags = {
    Name = "high_cpu_windows"
  }
}

# Disk Free - Windows

resource "aws_cloudwatch_metric_alarm" "disk_free_windows" {
  alarm_name          = "disk_free_windows"
  comparison_operator = "LessThanOrEqualToThreshold"
  evaluation_periods  = "2"
  datapoints_to_alarm = "2"
  metric_name         = "DISK_FREE"
  namespace           = "CWAgent"
  period              = "60"
  statistic           = "Average"
  threshold           = "15"
  alarm_description   = "This metric monitors the amount of free disk space on the instance. If the amount of free disk space falls below 15% for 2 minutes, the alarm will trigger: https://dsdmoj.atlassian.net/wiki/spaces/DSTT/pages/4305453159/Disk+Free+alarm+-+Windows"
  alarm_actions       = [aws_sns_topic.nomis_alarms.arn]
  tags = {
    Name = "disk_free_windows"
  }
}


# ==============================================================================
# Alerts - LINUX
# ==============================================================================

# Low Available Memory Alarm
resource "aws_cloudwatch_metric_alarm" "low_available_memory" {
  alarm_name          = "low_available_memory"
  comparison_operator = "LessThanOrEqualToThreshold"
  evaluation_periods  = "2"
  datapoints_to_alarm = "2"
  metric_name         = "mem_available_percent"
  namespace           = "CWAgent"
  period              = "60"
  statistic           = "Average"
  threshold           = "10"
  alarm_description   = "This metric monitors the amount of available memory. If the amount of available memory is less than 10% for 2 minutes, the alarm will trigger."
  alarm_actions       = [aws_sns_topic.nomis_alarms.arn]
  tags = {
    Name = "low_available_memory"
  }
}

# High CPU IOwait Alarm
resource "aws_cloudwatch_metric_alarm" "cpu_usage_iowait" {
  alarm_name          = "cpu_usage_iowait"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = "6"
  datapoints_to_alarm = "5"
  metric_name         = "cpu_usage_iowait"
  namespace           = "CWAgent"
  period              = "60"
  statistic           = "Average"
  threshold           = "90"
  alarm_description   = "This metric monitors the amount of CPU time spent waiting for I/O to complete. If the average CPU time spent waiting for I/O to complete is greater than 90% for 30 minutes, the alarm will trigger."
  alarm_actions       = [aws_sns_topic.nomis_alarms.arn]
  tags = {
    Name = "cpu_usage_iowait"
  }
}

# Disk Free Alarm
resource "aws_cloudwatch_metric_alarm" "disk_free" {
  alarm_name          = "disk_free"
  comparison_operator = "LessThanOrEqualToThreshold"
  evaluation_periods  = "2"
  datapoints_to_alarm = "2"
  metric_name         = "disk_free"
  namespace           = "CWAgent"
  period              = "60"
  statistic           = "Average"
  threshold           = "15"
  alarm_description   = "This metric monitors the amount of free disk space on the instance. If the amount of free disk space falls below 15% for 2 minutes, the alarm will trigger: https://dsdmoj.atlassian.net/wiki/spaces/DSTT/pages/4289822860/Disk+Free+alarm+-+Linux"
  alarm_actions       = [aws_sns_topic.nomis_alarms.arn]
  tags = {
    Name = "disk_free"
  }
}

# CPU Utilization Alarm
resource "aws_cloudwatch_metric_alarm" "cpu_utilization" {
  alarm_name          = "cpu_utilization"               # name of the alarm
  comparison_operator = "GreaterThanOrEqualToThreshold" # threshold to trigger the alarm state
  evaluation_periods  = "15"                            # how many periods over which to evaluate the alarm
  datapoints_to_alarm = "15"                            # how many datapoints must be breaching the threshold to trigger the alarm
  metric_name         = "CPUUtilization"                # name of the alarm's associated metric   
  namespace           = "AWS/EC2"                       # namespace of the alarm's associated metric
  period              = "60"                            # period in seconds over which the specified statistic is applied
  statistic           = "Average"                       # could be Average/Minimum/Maximum etc.
  threshold           = "95"                            # threshold for the alarm - see comparison_operator for usage
  alarm_description   = "Triggers if the average cpu remains at 95% utilization or above for 15 minutes"
  alarm_actions       = [aws_sns_topic.nomis_alarms.arn] # SNS topic to send the alarm to
  tags = {
    Name = "cpu_utilization"
  }
}

# ==============================================================================
# Oracle DB Alerts
# ==============================================================================

# Oracle db connection issue
resource "aws_cloudwatch_metric_alarm" "oracle_db_disconnected" {
  alarm_name          = "oracle_db_disconnected"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = "5"
  datapoints_to_alarm = "5"
  metric_name         = "collectd_exec-db_connected"
  namespace           = "CWAgent"
  period              = "60"
  statistic           = "Average"
  threshold           = "1"
  alarm_description   = "Oracle db connection to a particular SID is not working. See: https://dsdmoj.atlassian.net/wiki/spaces/DSTT/pages/4294246698/Oracle+db+connection+alarm for remediation steps."
  alarm_actions       = [aws_sns_topic.nomis_alarms.arn]
  tags = {
    Name = "oracle_db_disconnected"
  }
}

# Oracle batch processing issue
resource "aws_cloudwatch_metric_alarm" "oracle_batch_error" {
  alarm_name          = "oracle_batch_error"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = "5"
  datapoints_to_alarm = "5"
  metric_name         = "collectd_exec-batch_error"
  namespace           = "CWAgent"
  period              = "60"
  statistic           = "Average"
  threshold           = "1"
  alarm_description   = "Oracle db is either in long-running batch or failed batch status. See: https://dsdmoj.atlassian.net/wiki/spaces/DSTT/pages/4295000327/Oracle+Batch+alert for remediation steps."
  alarm_actions       = [aws_sns_topic.nomis_alarms.arn]
  tags = {
    Name = "oracle_batch_error"
  }
}

# ==============================================================================
# EC2 Instance Statuses
# ==============================================================================

# Instance Health Alarm
resource "aws_cloudwatch_metric_alarm" "instance_health_check" {
  alarm_name          = "instance_health_check_failed"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = "3"
  metric_name         = "StatusCheckFailed_Instance"
  namespace           = "AWS/EC2"
  period              = "60"
  statistic           = "Average"
  threshold           = "1"
  alarm_description   = "Instance status checks monitor the software and network configuration of your individual instance. When an instance status check fails, you typically must address the problem yourself: https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/monitoring-system-instance-status-check.html"
  alarm_actions       = [aws_sns_topic.nomis_alarms.arn]
  tags = {
    Name = "instance_health_check"
  }
}

# Status Check Alarm
resource "aws_cloudwatch_metric_alarm" "system_health_check" {
  alarm_name          = "system_health_check_failed"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = "3"
  metric_name         = "StatusCheckFailed_System"
  namespace           = "AWS/EC2"
  period              = "60"
  statistic           = "Average"
  threshold           = "1"
  alarm_description   = "System status checks monitor the AWS systems on which your instance runs. These checks detect underlying problems with your instance that require AWS involvement to repair: https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/monitoring-system-instance-status-check.html"
  alarm_actions       = [aws_sns_topic.nomis_alarms.arn]
  tags = {
    Name = "system_health_check"
  }
}
