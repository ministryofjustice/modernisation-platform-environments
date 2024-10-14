###############################################################
# Data Sources and CloudWatch Alarms for EC2 Instances Windows
###############################################################

# Create a data source to fetch the tags of each instance

data "aws_instances" "windows_tagged_instances" {
  filter {
    name   = "tag:patch_group"
    values = ["prod_win_patch"]
  }
}

# Data source for ImageId and InstanceType for each instance

data "aws_instance" "windows_instance_details" {
  for_each    = toset(data.aws_instances.windows_tagged_instances.ids)
  instance_id = each.value
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
    InstanceId   = each.key
    instance     = "C:"
    ImageId      = data.aws_instance.windows_instance_details[each.value].ami
    InstanceType = data.aws_instance.windows_instance_details[each.value].instance_type
    objectname   = "LogicalDisk"
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
    InstanceId   = each.key
    instance     = "D:"
    ImageId      = data.aws_instance.windows_instance_details[each.value].ami
    InstanceType = data.aws_instance.windows_instance_details[each.value].instance_type
    objectname   = "LogicalDisk"
  }
}

# Low Disk Alarms for all Windows instances with E Volumes
# There are currently 3 instances; RGVW021, RGVW022 and RGVW027
# Each have different alert thresholds

resource "aws_cloudwatch_metric_alarm" "low_disk_space_E_volume_rgvw021" {
  alarm_name          = "Low-Disk-Space-E-Volume-i-080498c4c9d25e6bd"
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
  alarm_actions       = ["arn:aws:sns:eu-west-2:817985104434:ppud-prod-cw-alerts"]
  dimensions = {
    InstanceId   = "i-080498c4c9d25e6bd"
    instance     = "E:"
    ImageId      = "ami-05ddec53aa481cbc3"
    InstanceType = "m5.2xlarge"
    objectname   = "LogicalDisk"
  }
}

resource "aws_cloudwatch_metric_alarm" "low_disk_space_E_volume_rgvw022" {
  alarm_name          = "Low-Disk-Space-E-Volume-i-029d2b17679dab982"
  comparison_operator = "LessThanOrEqualToThreshold"
  evaluation_periods  = "5"
  datapoints_to_alarm = "5"
  metric_name         = "LogicalDisk % Free Space"
  namespace           = "CWAgent"
  period              = "60"
  statistic           = "Average"
  threshold           = "0.5"
  treat_missing_data  = "notBreaching"
  alarm_description   = "This metric monitors the amount of free disk space on the instance. If the amount of free disk space falls below 5% for 5 minutes, the alarm will trigger"
  alarm_actions       = ["arn:aws:sns:eu-west-2:817985104434:ppud-prod-cw-alerts"]
  dimensions = {
    InstanceId   = "i-029d2b17679dab982"
    instance     = "E:"
    ImageId      = "ami-02f8251c8cdf2464f"
    InstanceType = "m5.xlarge"
    objectname   = "LogicalDisk"
  }
}

resource "aws_cloudwatch_metric_alarm" "low_disk_space_E_volume_rgvw027" {
  alarm_name          = "Low-Disk-Space-E-Volume-i-00cbccc46d25e77c6"
  comparison_operator = "LessThanOrEqualToThreshold"
  evaluation_periods  = "5"
  datapoints_to_alarm = "5"
  metric_name         = "LogicalDisk % Free Space"
  namespace           = "CWAgent"
  period              = "60"
  statistic           = "Average"
  threshold           = "1"
  treat_missing_data  = "notBreaching"
  alarm_description   = "This metric monitors the amount of free disk space on the instance. If the amount of free disk space falls below 5% for 5 minutes, the alarm will trigger"
  alarm_actions       = ["arn:aws:sns:eu-west-2:817985104434:ppud-prod-cw-alerts"]
  dimensions = {
    InstanceId   = "i-00cbccc46d25e77c6"
    instance     = "E:"
    ImageId      = "ami-0e203fec985af6465"
    InstanceType = "m5.xlarge"
    objectname   = "LogicalDisk"
  }
}

# Low Disk Alarms for all Windows instances with F Volumes
# There are currently 3 instances; RGVW021, RGVW022 and RGVW027
# Each have different alert thresholds

resource "aws_cloudwatch_metric_alarm" "low_disk_space_F_volume_rgvw021" {
  alarm_name          = "Low-Disk-Space-F-Volume-i-080498c4c9d25e6bd"
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
  alarm_actions       = ["arn:aws:sns:eu-west-2:817985104434:ppud-prod-cw-alerts"]
  dimensions = {
    InstanceId   = "i-080498c4c9d25e6bd"
    instance     = "F:"
    ImageId      = "ami-05ddec53aa481cbc3"
    InstanceType = "m5.2xlarge"
    objectname   = "LogicalDisk"
  }
}

resource "aws_cloudwatch_metric_alarm" "low_disk_space_F_volume_rgvw022" {
  alarm_name          = "Low-Disk-Space-F-Volume-i-029d2b17679dab982"
  comparison_operator = "LessThanOrEqualToThreshold"
  evaluation_periods  = "5"
  datapoints_to_alarm = "5"
  metric_name         = "LogicalDisk % Free Space"
  namespace           = "CWAgent"
  period              = "60"
  statistic           = "Average"
  threshold           = "0.5"
  treat_missing_data  = "notBreaching"
  alarm_description   = "This metric monitors the amount of free disk space on the instance. If the amount of free disk space falls below 5% for 5 minutes, the alarm will trigger"
  alarm_actions       = ["arn:aws:sns:eu-west-2:817985104434:ppud-prod-cw-alerts"]
  dimensions = {
    InstanceId   = "i-029d2b17679dab982"
    instance     = "E:"
    ImageId      = "ami-02f8251c8cdf2464f"
    InstanceType = "m5.xlarge"
    objectname   = "LogicalDisk"
  }
}

resource "aws_cloudwatch_metric_alarm" "low_disk_space_F_volume_rgvw027" {
  alarm_name          = "Low-Disk-Space-F-Volume-i-00cbccc46d25e77c6"
  comparison_operator = "LessThanOrEqualToThreshold"
  evaluation_periods  = "5"
  datapoints_to_alarm = "5"
  metric_name         = "LogicalDisk % Free Space"
  namespace           = "CWAgent"
  period              = "60"
  statistic           = "Average"
  threshold           = "2"
  treat_missing_data  = "notBreaching"
  alarm_description   = "This metric monitors the amount of free disk space on the instance. If the amount of free disk space falls below 5% for 5 minutes, the alarm will trigger"
  alarm_actions       = ["arn:aws:sns:eu-west-2:817985104434:ppud-prod-cw-alerts"]
  dimensions = {
    InstanceId   = "i-00cbccc46d25e77c6"
    instance     = "F:"
    ImageId      = "ami-0e203fec985af6465"
    InstanceType = "m5.xlarge"
    objectname   = "LogicalDisk"
  }
}

# Low Disk Alarms for all Windows instances with G Volumes
# There are currently 3 instances; RGVW021 and RGVW022
# Each have different alert thresholds

resource "aws_cloudwatch_metric_alarm" "low_disk_space_G_volume_rgvw021" {
  alarm_name          = "Low-Disk-Space-G-Volume-i-080498c4c9d25e6bd"
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
  alarm_actions       = ["arn:aws:sns:eu-west-2:817985104434:ppud-prod-cw-alerts"]
  dimensions = {
    InstanceId   = "i-080498c4c9d25e6bd"
    instance     = "G:"
    ImageId      = "ami-05ddec53aa481cbc3"
    InstanceType = "m5.2xlarge"
    objectname   = "LogicalDisk"
  }
}

resource "aws_cloudwatch_metric_alarm" "low_disk_space_G_volume_rgvw022" {
  alarm_name          = "Low-Disk-Space-G-Volume-i-029d2b17679dab982"
  comparison_operator = "LessThanOrEqualToThreshold"
  evaluation_periods  = "5"
  datapoints_to_alarm = "5"
  metric_name         = "LogicalDisk % Free Space"
  namespace           = "CWAgent"
  period              = "60"
  statistic           = "Average"
  threshold           = "2"
  treat_missing_data  = "notBreaching"
  alarm_description   = "This metric monitors the amount of free disk space on the instance. If the amount of free disk space falls below 5% for 5 minutes, the alarm will trigger"
  alarm_actions       = ["arn:aws:sns:eu-west-2:817985104434:ppud-prod-cw-alerts"]
  dimensions = {
    InstanceId   = "i-029d2b17679dab982"
    instance     = "G:"
    ImageId      = "ami-02f8251c8cdf2464f"
    InstanceType = "m5.xlarge"
    objectname   = "LogicalDisk"
  }
}

# Low Disk Alarms for all Windows instances with H Volumes
# There is currently only 1 instance RGVW027

resource "aws_cloudwatch_metric_alarm" "low_disk_space_H_volume_rgvw027" {
  alarm_name          = "Low-Disk-Space-H-Volume-i-00cbccc46d25e77c6"
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
  alarm_actions       = ["arn:aws:sns:eu-west-2:817985104434:ppud-prod-cw-alerts"]
  dimensions = {
    InstanceId   = "i-00cbccc46d25e77c6"
    instance     = "H:"
    ImageId      = "ami-0e203fec985af6465"
    InstanceType = "m5.xlarge"
    objectname   = "LogicalDisk"
  }
}

# Low Available Memory Alarm

resource "aws_cloudwatch_metric_alarm" "Memory_percentage_Committed_Bytes_In_Use" {
  for_each            = toset(data.aws_instances.windows_tagged_instances.ids)
  alarm_name          = "Memory-Percentage-Committed-Bytes-In-Use-${each.key}"
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
  alarm_name          = "CPU-Usage-IOWait-${each.key}"
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

# High CPU Utilization Alarm

resource "aws_cloudwatch_metric_alarm" "cpu" {
  for_each            = toset(data.aws_instances.windows_tagged_instances.ids)
  alarm_name          = "CPU-Utilisation-High-${each.key}" # name of the alarm
  comparison_operator = "GreaterThanOrEqualToThreshold"    # threshold to trigger the alarm state
  period              = "60"                               # period in seconds over which the specified statistic is applied
  threshold           = "90"                               # threshold for the alarm - see comparison_operator for usage
  evaluation_periods  = "3"                                # how many periods over which to evaluate the alarm
  datapoints_to_alarm = "2"                                # how many datapoints must be breaching the threshold to trigger the alarm
  metric_name         = "CPUUtilization"                   # name of the alarm's associated metric
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

# EC2 Instance Health Alarm

resource "aws_cloudwatch_metric_alarm" "instance_health_check" {
  for_each            = toset(data.aws_instances.windows_tagged_instances.ids)
  alarm_name          = "Instance-Health-Check-Failed-${each.key}"
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

# EC2 Status Check Alarm

resource "aws_cloudwatch_metric_alarm" "system_health_check" {
  for_each            = toset(data.aws_instances.windows_tagged_instances.ids)
  alarm_name          = "System-Health-Check-Failed-${each.key}"
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
  alarm_name          = "IIS-Failure-${each.key}"
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
