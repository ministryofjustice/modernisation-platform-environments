# =====================
# Alerts - EC2 Linux
# =====================

# Create a data source to fetch the tags of each instance
data "aws_instances" "linux_tagged_instances" {
  filter {
    name   = "tag:patch_group"
    values = ["prod_lin_patch"]
  }
}

# Data source for ImageId and InstanceType for each instance
data "aws_instance" "linux_instance_details" {
  for_each    = toset(data.aws_instances.linux_tagged_instances.ids)
  instance_id = each.value
}

# Low Disk Alarm for all Linux instances with Root Volumes

resource "aws_cloudwatch_metric_alarm" "low_disk_space_root_volume" {
  for_each            = toset(data.aws_instances.linux_tagged_instances.ids)
  alarm_name          = "Low-Disk-Space-Root-Volume-${each.key}"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = "5"
  datapoints_to_alarm = "5"
  metric_name         = "disk_used_percent"
  namespace           = "CWAgent"
  period              = "60"
  statistic           = "Average"
  threshold           = "90"
  treat_missing_data  = "notBreaching"
  alarm_description   = "This metric monitors the amount of free disk space on the instance. If the amount of free disk space falls below 10% for 5 minutes, the alarm will trigger"
  alarm_actions       = [aws_sns_topic.cw_alerts[0].arn]
  dimensions = {
    InstanceId = each.key
    path   = "/"
    ImageId    = data.aws_instance.linux_instance_details[each.value].ami
    InstanceType = data.aws_instance.linux_instance_details[each.value].instance_type
    device     = "nvme0n1p1"
    fstype     = "xfs"
  }
}


# Disk Free Alarm
resource "aws_cloudwatch_metric_alarm" "linux_high_disk_usage" {
  for_each            = toset(data.aws_instances.linux_tagged_instances.ids)
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


#======================
# CPU Utilization Alarm
#======================

resource "aws_cloudwatch_metric_alarm" "linux_cpu" {
  for_each            = toset(data.aws_instances.linux_tagged_instances.ids)
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

# High CPU IOwait Alarm
resource "aws_cloudwatch_metric_alarm" "linux_cpu_usage_iowait" {
  for_each            = toset(data.aws_instances.linux_tagged_instances.ids)
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



# ===========================
# Low Available Memory Alarm
# ===========================

resource "aws_cloudwatch_metric_alarm" "linux_ec2_high_memory_usage" {
  for_each            = toset(data.aws_instances.linux_tagged_instances.ids)
  alarm_name          = "high-memory-usage-${each.key}"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = "3"
  datapoints_to_alarm = "2"
  metric_name         = "mem_used_percent"
  namespace           = "CWAgent"
  period              = "60"
  statistic           = "Average"
  threshold           = "90"
  treat_missing_data  = "notBreaching"
  alarm_description   = "This metric monitors the memory used percentage on the instance. If the memory used above 90% for 2 minutes, the alarm will trigger"
  alarm_actions       = [aws_sns_topic.cw_alerts[0].arn]
  dimensions = {
    InstanceId = each.key
  }
}


resource "aws_cloudwatch_metric_alarm" "linux_low_available_memory" {
  for_each            = toset(data.aws_instances.linux_tagged_instances.ids)
  alarm_name          = "low-available-memory-${each.key}"
  comparison_operator = "LessThanOrEqualToThreshold"
  period              = "60"
  threshold           = "10"
  evaluation_periods  = "3"
  datapoints_to_alarm = "2"
  metric_name         = "mem_available_percent"
  treat_missing_data  = "notBreaching"
  namespace           = "CWAgent"
  statistic           = "Average"
  alarm_description   = "This metric monitors the amount of available memory. If the amount of available memory is less than 10% for 2 minutes, the alarm will trigger."
  alarm_actions       = [aws_sns_topic.cw_alerts[0].arn]
  dimensions = {
    InstanceId = each.key
  }
}


# ======================
# EC2 Instance Statuses
# ======================

# Instance Health Alarm
resource "aws_cloudwatch_metric_alarm" "linux_instance_health_check" {
  for_each            = toset(data.aws_instances.linux_tagged_instances.ids)
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
resource "aws_cloudwatch_metric_alarm" "linux_system_health_check" {
  for_each            = toset(data.aws_instances.linux_tagged_instances.ids)
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

#Log Groups

resource "aws_cloudwatch_log_group" "Linux-Services-Logs" {
  count             = local.is-production == true ? 1 : 0
  name              = "Linux-Services-Logs"
  retention_in_days = 365
}

#Metric Filters

resource "aws_cloudwatch_log_metric_filter" "Linux-ServiceStatus-Running" {
  count          = local.is-production == true ? 1 : 0
  name           = "Linux-ServiceStatus-Running"
  log_group_name = aws_cloudwatch_log_group.Linux-Services-Logs[count.index].name
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

resource "aws_cloudwatch_log_metric_filter" "Linux-ServiceStatus-NotRunning" {
  count          = local.is-production == true ? 1 : 0
  name           = "Linux-ServiceStatus-NotRunning"
  log_group_name = aws_cloudwatch_log_group.Linux-Services-Logs[count.index].name
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