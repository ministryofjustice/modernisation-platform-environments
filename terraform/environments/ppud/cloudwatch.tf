
variable "instances" {
    default = ["i-00413756d2dfcf6d2", "i-0dba6054c0f5f7a11", "i-014bce95a85aaeede", "i-0b5ef7cb90938fb82", "i-04bbb6312b86648be"]
}

# =============================
# Cloud Watch Alerts - Windows
# =============================

# Low Available Memory Alarm
resource "aws_cloudwatch_metric_alarm" "low_available_memory" {
  count               = length(var.instances)
  alarm_name          = "Prod-${count.index}-low-available-memory"
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
  alarm_actions       = [aws_sns_topic.cw_alerts.arn]
  dimensions = { InstanceId = "${element(var.instances, count.index)}"}
    tags = {
    Name = "low_available_memory"
  }
}

# High CPU IOwait Alarm
resource "aws_cloudwatch_metric_alarm" "cpu_usage_iowait" {
  count               = length(var.instances)
  alarm_name          = "Prod-${count.index}-cpu-usage-iowait"
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
  alarm_actions       = [aws_sns_topic.cw_alerts.arn]
  dimensions = { InstanceId = "${element(var.instances, count.index)}"}
    tags = {
    Name = "cpu_usage_iowait"
  }
}

# Disk Free Alarm
resource "aws_cloudwatch_metric_alarm" "high_disk_usage" {
  count = length(var.instances)
  alarm_name = "Prod-${count.index}-high-disk-usage"
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
  alarm_actions       = [aws_sns_topic.cw_alerts.arn]
  dimensions = { InstanceId = "${element(var.instances, count.index)}"}
   tags = {
    Name = "disk_free"
  }
}

# CPU Utilization Alarm
resource "aws_cloudwatch_metric_alarm" "cpu" {
  count               = length(var.instances)
  alarm_name          = "Prod-${count.index}-CPU-High"    # name of the alarm
  comparison_operator = "GreaterThanOrEqualToThreshold"   # threshold to trigger the alarm state
  period              = "60"                              # period in seconds over which the specified statistic is applied
  threshold           = "80"                              # threshold for the alarm - see comparison_operator for usage
  evaluation_periods  = "3"                               # how many periods over which to evaluate the alarm
  datapoints_to_alarm = "2"                               # how many datapoints must be breaching the threshold to trigger the alarm
  metric_name         = "CPUUtilization"                  # name of the alarm's associated metric
  treat_missing_data  = "notBreaching"
  namespace           = "AWS/EC2"                         # namespace of the alarm's associated metric
  statistic           = "Average"                         # could be Average/Minimum/Maximum etc.
  alarm_description   = "Monitors ec2 cpu utilisation"
  alarm_actions       = [aws_sns_topic.cw_alerts.arn]
  dimensions = { InstanceId = "${element(var.instances, count.index)}"}
    tags = {
    Name = "CPU_High"
  }
}

# ======================
# EC2 Instance Statuses
# ======================

# Instance Health Alarm
resource "aws_cloudwatch_metric_alarm" "instance_health_check" {
  count               = length(var.instances)
  alarm_name          = "Prod-${count.index}-instance-health-check-failed"
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
  alarm_actions       = [aws_sns_topic.cw_alerts.arn]
  dimensions = { InstanceId = "${element(var.instances, count.index)}"}
    tags = {
    Name = "instance_health_check"
  }
}

# Status Check Alarm
resource "aws_cloudwatch_metric_alarm" "system_health_check" {
  count               = length(var.instances)
  alarm_name          = "Prod-${count.index}-system-health-check-failed"
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
  alarm_actions       = [aws_sns_topic.cw_alerts.arn]
  dimensions = { InstanceId = "${element(var.instances, count.index)}"}
  tags = {
    Name = "system_health_check"
  }
}


# ====================
# IIS and Event Logs
# ====================

# Status Check Alarm
resource "aws_cloudwatch_metric_alarm" "Windows_IIS_check" {
  count               = length(var.instances)
  alarm_name          = "Prod-${count.index}-IIS-failure"
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
  alarm_actions       = [aws_sns_topic.cw_alerts.arn]
  dimensions = { InstanceId = "${element(var.instances, count.index)}"}
    tags = {
    Name = "system_health_check"
  }
}