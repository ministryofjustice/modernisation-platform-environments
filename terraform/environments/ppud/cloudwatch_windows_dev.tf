
# Create a data source to fetch the tags of each instance
data "aws_instances" "dev_windows_tagged_instances" {
  filter {
    name   = "tag:patch_group"
    values = ["dev_win_patch"]
  }
}

data "aws_instance" "instance_details" {
  for_each    = toset(data.aws_instances.dev_windows_tagged_instances.ids)
  instance_id = each.value
}

# Data to tag all windows servers with D volumes
data "aws_instances" "d_volume_tagged_instances" {
  filter {
    name   = "tag:d_volume"
    values = ["true"]
  }
}

# Data to tag all windows servers with E volumes
data "aws_instances" "e_volume_tagged_instances" {
  filter {
    name   = "tag:e_volume"
    values = ["true"]
  }
}

# Low Disk Alarm for all Dev Windows instances with C Volumes

resource "aws_cloudwatch_metric_alarm" "low_disk_space_C_volume_dev" {
  for_each            = toset(data.aws_instances.dev_windows_tagged_instances.ids)
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
 #alarm_actions       = [aws_sns_topic.ec2_cloudwatch_alarms[0].arn]
  dimensions = {
    InstanceId = each.key
    instance   = "C:"
    ImageId    = data.aws_instance.instance_details[each.value].ami
    InstanceType = data.aws_instance.instance_details[each.value].instance_type
    objectname = "LogicalDisk"
  }
}

# Low Disk Alarm for all Dev Windows instances with D Volumes

resource "aws_cloudwatch_metric_alarm" "low_disk_space_D_volume_dev" {
  for_each            = toset(data.aws_instances.dev_windows_tagged_instances.ids)
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
 #alarm_actions       = [aws_sns_topic.ec2_cloudwatch_alarms[0].arn]
  dimensions = {
    InstanceId = each.key
    instance   = "D:"
    ImageId    = data.aws_instance.instance_details[each.value].ami
    InstanceType = data.aws_instance.instance_details[each.value].instance_type
    objectname = "LogicalDisk"
  }
}

# Low Disk Alarm for all Dev Windows instances with E Volumes

resource "aws_cloudwatch_metric_alarm" "low_disk_space_E_volume_dev" {
  for_each            = toset(data.aws_instances.e_volume_tagged_instances.ids)
  alarm_name          = "Low-Disk-Space-E-Volume-${each.key}"
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
 #alarm_actions       = [aws_sns_topic.ec2_cloudwatch_alarms[0].arn]
  dimensions = {
    InstanceId = each.key
    instance   = "E:"
    ImageId    = data.aws_instance.instance_details[each.value].ami
    InstanceType = data.aws_instance.instance_details[each.value].instance_type
    objectname = "LogicalDisk"
  }
}