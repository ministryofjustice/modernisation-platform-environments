############################################################
# Data Sources and CloudWatch Alarms for EC2 Instances Linux
############################################################

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
    InstanceId   = each.key
    path         = "/"
    ImageId      = data.aws_instance.linux_instance_details[each.value].ami
    InstanceType = data.aws_instance.linux_instance_details[each.value].instance_type
    device       = "nvme0n1p1"
    fstype       = "xfs"
  }
}

# Low Disk Alarm for Linux instance with additional log partition

resource "aws_cloudwatch_metric_alarm" "low_disk_space_log_volume" {
  count               = local.is-production == true ? 1 : 0
  alarm_name          = "Low-Disk-Space-Log-Volume-i-0f393d9ed4e53da68"
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
    InstanceId   = "i-0f393d9ed4e53da68"
    path         = "/archive"
    ImageId      = "ami-0f43890c2b4907c29"
    InstanceType = "m5.large"
    device       = "nvme1n1p1"
    fstype       = "ext4"
  }
}

# High CPU Utilization Alarm

resource "aws_cloudwatch_metric_alarm" "linux_cpu" {
  for_each            = toset(data.aws_instances.linux_tagged_instances.ids)
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

# High CPU IOwait Alarm

resource "aws_cloudwatch_metric_alarm" "linux_cpu_usage_iowait" {
  for_each            = toset(data.aws_instances.linux_tagged_instances.ids)
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

# High Memory Utilisation Memory Alarm

resource "aws_cloudwatch_metric_alarm" "linux_ec2_high_memory_usage" {
  for_each            = toset(data.aws_instances.linux_tagged_instances.ids)
  alarm_name          = "Memory-Usage-High-${each.key}"
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

# ======================
# EC2 Instance Statuses
# ======================

# EC2 Instance Health Alarm

resource "aws_cloudwatch_metric_alarm" "linux_instance_health_check" {
  for_each            = toset(data.aws_instances.linux_tagged_instances.ids)
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

resource "aws_cloudwatch_metric_alarm" "linux_system_health_check" {
  for_each            = toset(data.aws_instances.linux_tagged_instances.ids)
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

# Docker Service Status

resource "aws_cloudwatch_metric_alarm" "service_status_docker_rgsl200" {
  count               = local.is-production == true ? 1 : 0
  alarm_name          = "Service-Status-Docker-i-0f393d9ed4e53da68"
  comparison_operator = "LessThanThreshold"
  evaluation_periods  = "1"
  datapoints_to_alarm = "1"
  metric_name         = "IsRunning"
  namespace           = "ServiceStatus"
  period              = "60"
  statistic           = "Average"
  threshold           = "1"
  treat_missing_data  = "notBreaching"
  alarm_description   = "This metric monitors the docker service status. If the metric falls to 0 [not running] then the alarm will trigger."
  alarm_actions       = [aws_sns_topic.cw_alerts[0].arn]
  dimensions = {
    Instance = "i-0f393d9ed4e53da68"
    Service  = "docker"
  }
}

resource "aws_cloudwatch_metric_alarm" "service_status_docker_401_cjsm" {
  count               = local.is-production == true ? 1 : 0
  alarm_name          = "Service-Status-Docker-i-0e8e2a182917bcf26"
  comparison_operator = "LessThanThreshold"
  evaluation_periods  = "1"
  datapoints_to_alarm = "1"
  metric_name         = "IsRunning"
  namespace           = "ServiceStatus"
  period              = "60"
  statistic           = "Average"
  threshold           = "1"
  treat_missing_data  = "notBreaching"
  alarm_description   = "This metric monitors the docker service status. If the metric falls to 0 [not running] then the alarm will trigger."
  alarm_actions       = [aws_sns_topic.cw_alerts[0].arn]
  dimensions = {
    Instance = "i-0e8e2a182917bcf26"
    Service  = "docker"
  }
}

resource "aws_cloudwatch_metric_alarm" "service_status_docker_400_non_cjsm" {
  count               = local.is-production == true ? 1 : 0
  alarm_name          = "Service-Status-Docker-i-01b4cc138ac95a506"
  comparison_operator = "LessThanThreshold"
  evaluation_periods  = "1"
  datapoints_to_alarm = "1"
  metric_name         = "IsRunning"
  namespace           = "ServiceStatus"
  period              = "60"
  statistic           = "Average"
  threshold           = "1"
  treat_missing_data  = "notBreaching"
  alarm_description   = "This metric monitors the docker service status. If the metric falls to 0 [not running] then the alarm will trigger."
  alarm_actions       = [aws_sns_topic.cw_alerts[0].arn]
  dimensions = {
    Instance = "i-01b4cc138ac95a506"
    Service  = "docker"
  }
}

# Port 25 Connectivity to CJSM mail relay or internal mail relay (rgsl200)

resource "aws_cloudwatch_metric_alarm" "port_25_status_check_401_cjsm" {
  count               = local.is-production == true ? 1 : 0
  alarm_name          = "CJSM-Port-25-Status-Check-i-0e8e2a182917bcf26"
  comparison_operator = "LessThanThreshold"
  evaluation_periods  = "1"
  datapoints_to_alarm = "1"
  metric_name         = "PortStatus"
  namespace           = "Port"
  period              = "60"
  statistic           = "Average"
  threshold           = "1"
  treat_missing_data  = "notBreaching"
  alarm_description   = "This metric monitors the port 25 status check to smtp.cjsm.net . If the metric falls to 0 [unable to connect] then the alarm will trigger."
  alarm_actions       = [aws_sns_topic.cw_alerts[0].arn]
  dimensions = {
    Instance = "i-0e8e2a182917bcf26"
    Port     = "Port25"
  }
}