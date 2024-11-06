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
  count               = local.is-production == true ? 1 : 0
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
  alarm_actions       = [aws_sns_topic.cw_alerts[0].arn]
  dimensions = {
    InstanceId   = "i-080498c4c9d25e6bd"
    instance     = "E:"
    ImageId      = "ami-05ddec53aa481cbc3"
    InstanceType = "m5.2xlarge"
    objectname   = "LogicalDisk"
  }
}

resource "aws_cloudwatch_metric_alarm" "low_disk_space_E_volume_rgvw022" {
  count               = local.is-production == true ? 1 : 0
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
  alarm_actions       = [aws_sns_topic.cw_alerts[0].arn]
  dimensions = {
    InstanceId   = "i-029d2b17679dab982"
    instance     = "E:"
    ImageId      = "ami-02f8251c8cdf2464f"
    InstanceType = "m5.xlarge"
    objectname   = "LogicalDisk"
  }
}

resource "aws_cloudwatch_metric_alarm" "low_disk_space_E_volume_rgvw027" {
  count               = local.is-production == true ? 1 : 0
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
  alarm_actions       = [aws_sns_topic.cw_alerts[0].arn]
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
  count               = local.is-production == true ? 1 : 0
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
  alarm_actions       = [aws_sns_topic.cw_alerts[0].arn]
  dimensions = {
    InstanceId   = "i-080498c4c9d25e6bd"
    instance     = "F:"
    ImageId      = "ami-05ddec53aa481cbc3"
    InstanceType = "m5.2xlarge"
    objectname   = "LogicalDisk"
  }
}

resource "aws_cloudwatch_metric_alarm" "low_disk_space_F_volume_rgvw022" {
  count               = local.is-production == true ? 1 : 0
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
  alarm_actions       = [aws_sns_topic.cw_alerts[0].arn]
  dimensions = {
    InstanceId   = "i-029d2b17679dab982"
    instance     = "E:"
    ImageId      = "ami-02f8251c8cdf2464f"
    InstanceType = "m5.xlarge"
    objectname   = "LogicalDisk"
  }
}

resource "aws_cloudwatch_metric_alarm" "low_disk_space_F_volume_rgvw027" {
  count               = local.is-production == true ? 1 : 0
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
  alarm_actions       = [aws_sns_topic.cw_alerts[0].arn]
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
  count               = local.is-production == true ? 1 : 0
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
  alarm_actions       = [aws_sns_topic.cw_alerts[0].arn]
  dimensions = {
    InstanceId   = "i-080498c4c9d25e6bd"
    instance     = "G:"
    ImageId      = "ami-05ddec53aa481cbc3"
    InstanceType = "m5.2xlarge"
    objectname   = "LogicalDisk"
  }
}

resource "aws_cloudwatch_metric_alarm" "low_disk_space_G_volume_rgvw022" {
  count               = local.is-production == true ? 1 : 0
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
  alarm_actions       = [aws_sns_topic.cw_alerts[0].arn]
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
  count               = local.is-production == true ? 1 : 0
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
  alarm_actions       = [aws_sns_topic.cw_alerts[0].arn]
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

# Malware Event Signature Update Failed

resource "aws_cloudwatch_metric_alarm" "malware_event_signature_update_failed" {
  for_each            = toset(data.aws_instances.windows_tagged_instances.ids)
  alarm_name          = "Malware-Event-Signature-Update-Failed-${each.key}"
  comparison_operator = "GreaterThanThreshold"
  period              = "60"
  threshold           = "0"
  evaluation_periods  = "1"
  datapoints_to_alarm = "1"
  metric_name         = "MalwareSignatureFailed"
  treat_missing_data  = "notBreaching"
  namespace           = "WindowsDefender"
  statistic           = "Sum"
  alarm_description   = "Monitors for windows defender malware signature update failed events"
  alarm_actions       = [aws_sns_topic.cw_alerts[0].arn]
  dimensions = {
    Instance               = each.key
    MalwareSignatureFailed = "MalwareSignatureFailed"
  }
}

# Malware Event State Detected

resource "aws_cloudwatch_metric_alarm" "malware_event_state_detected" {
  for_each            = toset(data.aws_instances.windows_tagged_instances.ids)
  alarm_name          = "Malware-Event-State-Detected-${each.key}"
  comparison_operator = "GreaterThanThreshold"
  period              = "60"
  threshold           = "0"
  evaluation_periods  = "1"
  datapoints_to_alarm = "1"
  metric_name         = "MalwareStateDetected"
  treat_missing_data  = "notBreaching"
  namespace           = "WindowsDefender"
  statistic           = "Sum"
  alarm_description   = "Monitors for windows defender malware state detected events"
  alarm_actions       = [aws_sns_topic.cw_alerts[0].arn]
  dimensions = {
    Instance             = each.key
    MalwareStateDetected = "MalwareStateDetected"
  }
}

# Malware Event Scan Failed

resource "aws_cloudwatch_metric_alarm" "malware_event_scan_failed" {
  for_each            = toset(data.aws_instances.windows_tagged_instances.ids)
  alarm_name          = "Malware-Event-Scan-Failed-${each.key}"
  comparison_operator = "GreaterThanThreshold"
  period              = "60"
  threshold           = "0"
  evaluation_periods  = "1"
  datapoints_to_alarm = "1"
  metric_name         = "MalwareScanFailed"
  treat_missing_data  = "notBreaching"
  namespace           = "WindowsDefender"
  statistic           = "Sum"
  alarm_description   = "Monitors for windows defender malware scan failed events"
  alarm_actions       = [aws_sns_topic.cw_alerts[0].arn]
  dimensions = {
    Instance          = each.key
    MalwareScanFailed = "MalwareScanFailed"
  }
}

# Malware Event Engine Update Failed

resource "aws_cloudwatch_metric_alarm" "malware_event_engine_update_failed" {
  for_each            = toset(data.aws_instances.windows_tagged_instances.ids)
  alarm_name          = "Malware-Event-Engine-Update-Failed-${each.key}"
  comparison_operator = "GreaterThanThreshold"
  period              = "60"
  threshold           = "0"
  evaluation_periods  = "1"
  datapoints_to_alarm = "1"
  metric_name         = "MalwareEngineFailed"
  treat_missing_data  = "notBreaching"
  namespace           = "WindowsDefender"
  statistic           = "Sum"
  alarm_description   = "Monitors for windows defender malware engine update events"
  alarm_actions       = [aws_sns_topic.cw_alerts[0].arn]
  dimensions = {
    Instance            = each.key
    MalwareEngineFailed = "MalwareEngineFailed"
  }
}

# Malware Event Engine Out of Date

resource "aws_cloudwatch_metric_alarm" "malware_event_engine_out_of_date" {
  for_each            = toset(data.aws_instances.windows_tagged_instances.ids)
  alarm_name          = "Malware-Event-Engine-Out-Of-Date-${each.key}"
  comparison_operator = "GreaterThanThreshold"
  period              = "60"
  threshold           = "0"
  evaluation_periods  = "1"
  datapoints_to_alarm = "1"
  metric_name         = "MalwareEngineOutofDate"
  treat_missing_data  = "notBreaching"
  namespace           = "WindowsDefender"
  statistic           = "Sum"
  alarm_description   = "Monitors for windows defender malware engine out of date events"
  alarm_actions       = [aws_sns_topic.cw_alerts[0].arn]
  dimensions = {
    Instance               = each.key
    MalwareEngineOutofDate = "MalwareEngineOutofDate"
  }
}

# Malware Event Behavior Detected

resource "aws_cloudwatch_metric_alarm" "malware_event_behavior_detected" {
  for_each            = toset(data.aws_instances.windows_tagged_instances.ids)
  alarm_name          = "Malware-Event-Engine-Behavior-Detected-${each.key}"
  comparison_operator = "GreaterThanThreshold"
  period              = "60"
  threshold           = "0"
  evaluation_periods  = "1"
  datapoints_to_alarm = "1"
  metric_name         = "MalwareBehaviorDetected"
  treat_missing_data  = "notBreaching"
  namespace           = "WindowsDefender"
  statistic           = "Sum"
  alarm_description   = "Monitors for windows defender malware behavior detected events"
  alarm_actions       = [aws_sns_topic.cw_alerts[0].arn]
  dimensions = {
    Instance                = each.key
    MalwareBehaviorDetected = "MalwareBehaviorDetected"
  }
}

# Service Status Alarms

# IIS Admin Service

resource "aws_cloudwatch_metric_alarm" "service_status_iisadmin_rgvw019" {
  count               = local.is-production == true ? 1 : 0
  alarm_name          = "Service-Status-IISAdmin-i-0dba6054c0f5f7a11"
  comparison_operator = "LessThanThreshold"
  evaluation_periods  = "1"
  datapoints_to_alarm = "1"
  metric_name         = "IsRunning"
  namespace           = "ServiceStatus"
  period              = "60"
  statistic           = "Average"
  threshold           = "1"
  treat_missing_data  = "notBreaching"
  alarm_description   = "This metric monitors the iis admin service. If the metric falls to 0 [not running] then the alarm will trigger."
  alarm_actions       = [aws_sns_topic.cw_alerts[0].arn]
  dimensions = {
    Instance = "i-0dba6054c0f5f7a11"
    Service  = "IISAdminService"
  }
}

resource "aws_cloudwatch_metric_alarm" "service_status_iisadmin_rgvw020" {
  count               = local.is-production == true ? 1 : 0
  alarm_name          = "Service-Status-IISAdmin-i-014bce95a85aaeede"
  comparison_operator = "LessThanThreshold"
  evaluation_periods  = "1"
  datapoints_to_alarm = "1"
  metric_name         = "IsRunning"
  namespace           = "ServiceStatus"
  period              = "60"
  statistic           = "Average"
  threshold           = "1"
  treat_missing_data  = "notBreaching"
  alarm_description   = "This metric monitors the iis admin service. If the metric falls to 0 [not running] then the alarm will trigger."
  alarm_actions       = [aws_sns_topic.cw_alerts[0].arn]
  dimensions = {
    Instance = "i-014bce95a85aaeede"
    Service  = "IISAdminService"
  }
}

# World Wide Web Publishing Service

resource "aws_cloudwatch_metric_alarm" "service_status_www_publishing_rgvw019" {
  count               = local.is-production == true ? 1 : 0
  alarm_name          = "Service-Status-WWW-Publishing-i-0dba6054c0f5f7a11"
  comparison_operator = "LessThanThreshold"
  evaluation_periods  = "1"
  datapoints_to_alarm = "1"
  metric_name         = "IsRunning"
  namespace           = "ServiceStatus"
  period              = "60"
  statistic           = "Average"
  threshold           = "1"
  treat_missing_data  = "notBreaching"
  alarm_description   = "This metric monitors the www publishing service. If the metric falls to 0 [not running] then the alarm will trigger."
  alarm_actions       = [aws_sns_topic.cw_alerts[0].arn]
  dimensions = {
    Instance = "i-0dba6054c0f5f7a11"
    Service  = "WorldWideWebPublishingService"
  }
}

resource "aws_cloudwatch_metric_alarm" "service_status_www_publishing_rgvw020" {
  count               = local.is-production == true ? 1 : 0
  alarm_name          = "Service-Status-WWW-Publishing-i-014bce95a85aaeede"
  comparison_operator = "LessThanThreshold"
  evaluation_periods  = "1"
  datapoints_to_alarm = "1"
  metric_name         = "IsRunning"
  namespace           = "ServiceStatus"
  period              = "60"
  statistic           = "Average"
  threshold           = "1"
  treat_missing_data  = "notBreaching"
  alarm_description   = "This metric monitors the www publishing service. If the metric falls to 0 [not running] then the alarm will trigger."
  alarm_actions       = [aws_sns_topic.cw_alerts[0].arn]
  dimensions = {
    Instance = "i-014bce95a85aaeede"
    Service  = "WorldWideWebPublishingService"
  }
}

resource "aws_cloudwatch_metric_alarm" "service_status_www_publishing_rgvw022" {
  count               = local.is-production == true ? 1 : 0
  alarm_name          = "Service-Status-WWW-Publishing-i-029d2b17679dab982"
  comparison_operator = "LessThanThreshold"
  evaluation_periods  = "1"
  datapoints_to_alarm = "1"
  metric_name         = "IsRunning"
  namespace           = "ServiceStatus"
  period              = "60"
  statistic           = "Average"
  threshold           = "1"
  treat_missing_data  = "notBreaching"
  alarm_description   = "This metric monitors the www publishing service. If the metric falls to 0 [not running] then the alarm will trigger."
  alarm_actions       = [aws_sns_topic.cw_alerts[0].arn]
  dimensions = {
    Instance = "i-029d2b17679dab982"
    Service  = "WorldWideWebPublishingService"
  }
}

resource "aws_cloudwatch_metric_alarm" "service_status_www_publishing_rgsw025" {
  count               = local.is-production == true ? 1 : 0
  alarm_name          = "Service-Status-WWW-Publishing-i-00413756d2dfcf6d2"
  comparison_operator = "LessThanThreshold"
  evaluation_periods  = "1"
  datapoints_to_alarm = "1"
  metric_name         = "IsRunning"
  namespace           = "ServiceStatus"
  period              = "60"
  statistic           = "Average"
  threshold           = "1"
  treat_missing_data  = "notBreaching"
  alarm_description   = "This metric monitors the www publishing service. If the metric falls to 0 [not running] then the alarm will trigger."
  alarm_actions       = [aws_sns_topic.cw_alerts[0].arn]
  dimensions = {
    Instance = "i-00413756d2dfcf6d2"
    Service  = "WorldWideWebPublishingService"
  }
}

resource "aws_cloudwatch_metric_alarm" "service_status_www_publishing_rgvw027" {
  count               = local.is-production == true ? 1 : 0
  alarm_name          = "Service-Status-WWW-Publishing-i-00cbccc46d25e77c6"
  comparison_operator = "LessThanThreshold"
  evaluation_periods  = "1"
  datapoints_to_alarm = "1"
  metric_name         = "IsRunning"
  namespace           = "ServiceStatus"
  period              = "60"
  statistic           = "Average"
  threshold           = "1"
  treat_missing_data  = "notBreaching"
  alarm_description   = "This metric monitors the www publishing service. If the metric falls to 0 [not running] then the alarm will trigger."
  alarm_actions       = [aws_sns_topic.cw_alerts[0].arn]
  dimensions = {
    Instance = "i-00cbccc46d25e77c6"
    Service  = "WorldWideWebPublishingService"
  }
}

resource "aws_cloudwatch_metric_alarm" "service_status_www_publishing_rgvw204" {
  count               = local.is-production == true ? 1 : 0
  alarm_name          = "Service-Status-WWW-Publishing-i-0b5ef7cb90938fb82"
  comparison_operator = "LessThanThreshold"
  evaluation_periods  = "1"
  datapoints_to_alarm = "1"
  metric_name         = "IsRunning"
  namespace           = "ServiceStatus"
  period              = "60"
  statistic           = "Average"
  threshold           = "1"
  treat_missing_data  = "notBreaching"
  alarm_description   = "This metric monitors the www publishing service. If the metric falls to 0 [not running] then the alarm will trigger."
  alarm_actions       = [aws_sns_topic.cw_alerts[0].arn]
  dimensions = {
    Instance = "i-0b5ef7cb90938fb82"
    Service  = "WorldWideWebPublishingService"
  }
}

resource "aws_cloudwatch_metric_alarm" "service_status_www_publishing_rgvw205" {
  count               = local.is-production == true ? 1 : 0
  alarm_name          = "Service-Status-WWW-Publishing-i-04bbb6312b86648be"
  comparison_operator = "LessThanThreshold"
  evaluation_periods  = "1"
  datapoints_to_alarm = "1"
  metric_name         = "IsRunning"
  namespace           = "ServiceStatus"
  period              = "60"
  statistic           = "Average"
  threshold           = "1"
  treat_missing_data  = "notBreaching"
  alarm_description   = "This metric monitors the www publishing service. If the metric falls to 0 [not running] then the alarm will trigger."
  alarm_actions       = [aws_sns_topic.cw_alerts[0].arn]
  dimensions = {
    Instance = "i-04bbb6312b86648be"
    Service  = "WorldWideWebPublishingService"
  }
}

# Printer Spooler Service

resource "aws_cloudwatch_metric_alarm" "service_status_printer_spooler_rgvw022" {
  count               = local.is-production == true ? 1 : 0
  alarm_name          = "Service-Status-Printer-Spooler-i-029d2b17679dab982"
  comparison_operator = "LessThanThreshold"
  evaluation_periods  = "1"
  datapoints_to_alarm = "1"
  metric_name         = "IsRunning"
  namespace           = "ServiceStatus"
  period              = "60"
  statistic           = "Average"
  threshold           = "1"
  treat_missing_data  = "notBreaching"
  alarm_description   = "This metric monitors the printer spooler service. If the metric falls to 0 [not running] then the alarm will trigger."
  alarm_actions       = [aws_sns_topic.cw_alerts[0].arn]
  dimensions = {
    Instance = "i-029d2b17679dab982"
    Service  = "PrintSpooler"
  }
}

resource "aws_cloudwatch_metric_alarm" "service_status_printer_spooler_rgvw027" {
  count               = local.is-production == true ? 1 : 0
  alarm_name          = "Service-Status-Printer-Spooler-i-00cbccc46d25e77c6"
  comparison_operator = "LessThanThreshold"
  evaluation_periods  = "1"
  datapoints_to_alarm = "1"
  metric_name         = "IsRunning"
  namespace           = "ServiceStatus"
  period              = "60"
  statistic           = "Average"
  threshold           = "1"
  treat_missing_data  = "notBreaching"
  alarm_description   = "This metric monitors the printer spooler service. If the metric falls to 0 [not running] then the alarm will trigger."
  alarm_actions       = [aws_sns_topic.cw_alerts[0].arn]
  dimensions = {
    Instance = "i-00cbccc46d25e77c6"
    Service  = "PrintSpooler"
  }
}

# SQL Server, Writer and Agent Services and SQL Backup Status

resource "aws_cloudwatch_metric_alarm" "service_status_sql_server_rgvw021" {
  count               = local.is-production == true ? 1 : 0
  alarm_name          = "Service-Status-SQL-Server-i-080498c4c9d25e6bd"
  comparison_operator = "LessThanThreshold"
  evaluation_periods  = "1"
  datapoints_to_alarm = "1"
  metric_name         = "IsRunning"
  namespace           = "ServiceStatus"
  period              = "60"
  statistic           = "Average"
  threshold           = "1"
  treat_missing_data  = "notBreaching"
  alarm_description   = "This metric monitors the SQL server service. If the metric falls to 0 [not running] then the alarm will trigger."
  alarm_actions       = [aws_sns_topic.cw_alerts[0].arn]
  dimensions = {
    Instance = "i-080498c4c9d25e6bd"
    Service  = "SQLServer(MSSQLSERVER)"
  }
}

resource "aws_cloudwatch_metric_alarm" "service_status_sql_server_writer_rgvw021" {
  count               = local.is-production == true ? 1 : 0
  alarm_name          = "Service-Status-SQL-Server-Writer-i-080498c4c9d25e6bd"
  comparison_operator = "LessThanThreshold"
  evaluation_periods  = "1"
  datapoints_to_alarm = "1"
  metric_name         = "IsRunning"
  namespace           = "ServiceStatus"
  period              = "60"
  statistic           = "Average"
  threshold           = "1"
  treat_missing_data  = "notBreaching"
  alarm_description   = "This metric monitors the SQL server writer service. If the metric falls to 0 [not running] then the alarm will trigger."
  alarm_actions       = [aws_sns_topic.cw_alerts[0].arn]
  dimensions = {
    Instance = "i-080498c4c9d25e6bd"
    Service  = "SQLServerVSSWriter"
  }
}

resource "aws_cloudwatch_metric_alarm" "service_status_sql_server_agent_rgvw021" {
  count               = local.is-production == true ? 1 : 0
  alarm_name          = "Service-Status-SQL-Server-Writer-i-080498c4c9d25e6bd"
  comparison_operator = "LessThanThreshold"
  evaluation_periods  = "1"
  datapoints_to_alarm = "1"
  metric_name         = "IsRunning"
  namespace           = "ServiceStatus"
  period              = "60"
  statistic           = "Average"
  threshold           = "1"
  treat_missing_data  = "notBreaching"
  alarm_description   = "This metric monitors the SQL server agent service. If the metric falls to 0 [not running] then the alarm will trigger."
  alarm_actions       = [aws_sns_topic.cw_alerts[0].arn]
  dimensions = {
    Instance = "i-080498c4c9d25e6bd"
    Service  = "SQLServerAgent(MSSQLSERVER)"
  }
}

resource "aws_cloudwatch_metric_alarm" "service_status_sql_server_backup_status_rgvw021" {
  count               = local.is-production == true ? 1 : 0
  alarm_name          = "Service-Status-SQL-Server-Backup-Status-i-080498c4c9d25e6bd"
  comparison_operator = "LessThanThreshold"
  evaluation_periods  = "1"
  datapoints_to_alarm = "1"
  metric_name         = "Successful"
  namespace           = "SQLBackupStatus"
  period              = "60"
  statistic           = "Average"
  threshold           = "1"
  treat_missing_data  = "notBreaching"
  alarm_description   = "This metric monitors the SQL server backup status. If the metric falls to 0 [not running] then the alarm will trigger."
  alarm_actions       = [aws_sns_topic.cw_alerts[0].arn]
  dimensions = {
    Instance = "i-080498c4c9d25e6bd"
  }
}

# PPUD Live and Crawler Services

resource "aws_cloudwatch_metric_alarm" "service_status_ppud_live_rgvw019" {
  count               = local.is-production == true ? 1 : 0
  alarm_name          = "Service-Status-PPUD-Live-i-0dba6054c0f5f7a11"
  comparison_operator = "LessThanThreshold"
  evaluation_periods  = "1"
  datapoints_to_alarm = "1"
  metric_name         = "IsRunning"
  namespace           = "ServiceStatus"
  period              = "60"
  statistic           = "Average"
  threshold           = "1"
  treat_missing_data  = "notBreaching"
  alarm_description   = "This metric monitors the PPUD live service. If the metric falls to 0 [not running] then the alarm will trigger."
  alarm_actions       = [aws_sns_topic.cw_alerts[0].arn]
  dimensions = {
    Instance = "i-0dba6054c0f5f7a11"
    Service  = "PPUDAutomatedProcessesLIVE"
  }
}

resource "aws_cloudwatch_metric_alarm" "service_status_ppud_live_rgvw020" {
  count               = local.is-production == true ? 1 : 0
  alarm_name          = "Service-Status-PPUD-Live-i-014bce95a85aaeede"
  comparison_operator = "LessThanThreshold"
  evaluation_periods  = "1"
  datapoints_to_alarm = "1"
  metric_name         = "IsRunning"
  namespace           = "ServiceStatus"
  period              = "60"
  statistic           = "Average"
  threshold           = "1"
  treat_missing_data  = "notBreaching"
  alarm_description   = "This metric monitors the PPUD live service. If the metric falls to 0 [not running] then the alarm will trigger."
  alarm_actions       = [aws_sns_topic.cw_alerts[0].arn]
  dimensions = {
    Instance = "i-014bce95a85aaeede"
    Service  = "PPUDAutomatedProcessesLIVE"
  }
}

resource "aws_cloudwatch_metric_alarm" "service_status_ppud_live_rgvw022" {
  count               = local.is-production == true ? 1 : 0
  alarm_name          = "Service-Status-PPUD-Live-i-029d2b17679dab982"
  comparison_operator = "LessThanThreshold"
  evaluation_periods  = "1"
  datapoints_to_alarm = "1"
  metric_name         = "IsRunning"
  namespace           = "ServiceStatus"
  period              = "60"
  statistic           = "Average"
  threshold           = "1"
  treat_missing_data  = "notBreaching"
  alarm_description   = "This metric monitors the PPUD live service. If the metric falls to 0 [not running] then the alarm will trigger."
  alarm_actions       = [aws_sns_topic.cw_alerts[0].arn]
  dimensions = {
    Instance = "i-029d2b17679dab982"
    Service  = "PPUDAutomatedProcessesLIVE"
  }
}

resource "aws_cloudwatch_metric_alarm" "service_status_ppud_crawler_rgvw022" {
  count               = local.is-production == true ? 1 : 0
  alarm_name          = "Service-Status-PPUD-Crawler-i-029d2b17679dab982"
  comparison_operator = "LessThanThreshold"
  evaluation_periods  = "1"
  datapoints_to_alarm = "1"
  metric_name         = "IsRunning"
  namespace           = "ServiceStatus"
  period              = "60"
  statistic           = "Average"
  threshold           = "1"
  treat_missing_data  = "notBreaching"
  alarm_description   = "This metric monitors the PPUD crawler service. If the metric falls to 0 [not running] then the alarm will trigger."
  alarm_actions       = [aws_sns_topic.cw_alerts[0].arn]
  dimensions = {
    Instance = "i-029d2b17679dab982"
    Service  = "PPUDPDFCrawlerP4Live"
  }
}

# Port 25 Connectivity to internal mail relay (rgsl200)

resource "aws_cloudwatch_metric_alarm" "port_25_status_check_rgvw019" {
  count               = local.is-production == true ? 1 : 0
  alarm_name          = "Port-25-Status-Check-i-0dba6054c0f5f7a11"
  comparison_operator = "LessThanThreshold"
  evaluation_periods  = "1"
  datapoints_to_alarm = "1"
  metric_name         = "True"
  namespace           = "PortStatus"
  period              = "60"
  statistic           = "Average"
  threshold           = "1"
  treat_missing_data  = "notBreaching"
  alarm_description   = "This metric monitors the port 25 status check to the internal mail relay (rgsl200). If the metric falls to 0 [unable to connect] then the alarm will trigger."
  alarm_actions       = [aws_sns_topic.cw_alerts[0].arn]
  dimensions = {
    Instance = "i-0dba6054c0f5f7a11"
    Port     = "Port-25"
  }
}

resource "aws_cloudwatch_metric_alarm" "port_25_status_check_rgvw020" {
  count               = local.is-production == true ? 1 : 0
  alarm_name          = "Port-25-Status-Check-i-0f393d9ed4e53da68"
  comparison_operator = "LessThanThreshold"
  evaluation_periods  = "1"
  datapoints_to_alarm = "1"
  metric_name         = "True"
  namespace           = "PortStatus"
  period              = "60"
  statistic           = "Average"
  threshold           = "1"
  treat_missing_data  = "notBreaching"
  alarm_description   = "This metric monitors the port 25 status check to the internal mail relay (rgsl200). If the metric falls to 0 [unable to connect] then the alarm will trigger."
  alarm_actions       = [aws_sns_topic.cw_alerts[0].arn]
  dimensions = {
    Instance = "i-0f393d9ed4e53da68"
    Port     = "Port-25"
  }
}

resource "aws_cloudwatch_metric_alarm" "port_25_status_check_rgvw022" {
  count               = local.is-production == true ? 1 : 0
  alarm_name          = "Port-25-Status-Check-i-029d2b17679dab982"
  comparison_operator = "LessThanThreshold"
  evaluation_periods  = "1"
  datapoints_to_alarm = "1"
  metric_name         = "True"
  namespace           = "PortStatus"
  period              = "60"
  statistic           = "Average"
  threshold           = "1"
  treat_missing_data  = "notBreaching"
  alarm_description   = "This metric monitors the port 25 status check to the internal mail relay (rgsl200). If the metric falls to 0 [unable to connect] then the alarm will trigger."
  alarm_actions       = [aws_sns_topic.cw_alerts[0].arn]
  dimensions = {
    Instance = "i-029d2b17679dab982"
    Port     = "Port-25"
  }
}

resource "aws_cloudwatch_metric_alarm" "port_25_status_check_rgvw027" {
  count               = local.is-production == true ? 1 : 0
  alarm_name          = "Port-25-Status-Check-i-00cbccc46d25e77c6"
  comparison_operator = "LessThanThreshold"
  evaluation_periods  = "1"
  datapoints_to_alarm = "1"
  metric_name         = "True"
  namespace           = "PortStatus"
  period              = "60"
  statistic           = "Average"
  threshold           = "1"
  treat_missing_data  = "notBreaching"
  alarm_description   = "This metric monitors the port 25 status check to the internal mail relay (rgsl200). If the metric falls to 0 [unable to connect] then the alarm will trigger."
  alarm_actions       = [aws_sns_topic.cw_alerts[0].arn]
  dimensions = {
    Instance = "i-00cbccc46d25e77c6"
    Port     = "Port-25"
  }
}