locals {
  topic       = var.topic
  instanceIds = var.instanceIds
  name        = var.name
}

# CPU Utilization
resource "aws_cloudwatch_metric_alarm" "cpu_utilization" {
  count                     = var.metric == "cpu" ? 1 : 0
  alarm_name                = "${local.name}-cpu_utilization"
  alarm_description         = "Monitors ec2 cpu utilisation"
  comparison_operator       = "GreaterThanOrEqualToThreshold"
  metric_name               = "CPUUtilization"
  namespace                 = "AWS/EC2"
  statistic                 = "Average"
  insufficient_data_actions = []

  evaluation_periods  = var.eval_periods
  datapoints_to_alarm = var.eval_periods
  period              = var.period
  threshold           = var.threshold
  alarm_actions       = [local.topic]
  dimensions = {
    instanceId = tostring(local.instanceIds)
  }
}

# Low Available Memory Alarm
resource "aws_cloudwatch_metric_alarm" "low_available_memory" {
  count               = var.metric == "mem" ? 1 : 0
  alarm_name          = "${local.name}-low_available_memory"
  alarm_description   = "This metric monitors the amount of available memory. If the amount of available memory is less than 10% for 2 minutes, the alarm will trigger."
  comparison_operator = "LessThanOrEqualToThreshold"
  metric_name         = "mem_available_percent"
  namespace           = "CWAgent"
  statistic           = "Average"

  evaluation_periods  = var.eval_periods
  datapoints_to_alarm = var.eval_periods
  period              = var.period
  threshold           = var.threshold
  alarm_actions       = [var.topic]
  dimensions = {
    instanceId = tostring(local.instanceIds)
  }
}

# Disk Free Alarm
resource "aws_cloudwatch_metric_alarm" "disk_free" {
  count               = var.metric == "disk" ? 1 : 0
  alarm_name          = "${local.name}-disk_free"
  alarm_description   = "This metric monitors the amount of free disk space on the instance. If the amount of free disk space falls below 15% for 2 minutes, the alarm will trigger"
  comparison_operator = "LessThanOrEqualToThreshold"
  metric_name         = "disk_free"
  namespace           = "CWAgent"
  statistic           = "Average"

  evaluation_periods  = var.eval_periods
  datapoints_to_alarm = var.eval_periods
  period              = var.period
  threshold           = var.threshold
  alarm_actions       = [var.topic]
  dimensions = {
    instanceId = tostring(local.instanceIds)
  }
}

# High CPU IOwait Alarm
resource "aws_cloudwatch_metric_alarm" "cpu_usage_iowait" {
  count               = var.metric == "iowait" ? 1 : 0
  alarm_name          = "${local.name}-cpu_usage_iowait"
  alarm_description   = "This metric monitors the amount of CPU time spent waiting for I/O to complete. If the average CPU time spent waiting for I/O to complete is greater than 90% for 30 minutes, the alarm will trigger."
  comparison_operator = "GreaterThanOrEqualToThreshold"
  metric_name         = "cpu_usage_iowait"
  namespace           = "CWAgent"
  statistic           = "Average"

  evaluation_periods  = var.eval_periods
  datapoints_to_alarm = var.eval_periods
  period              = var.period
  threshold           = var.threshold
  alarm_actions       = [var.topic]
  dimensions = {
    instanceId = tostring(local.instanceIds)
  }

}


# ==============================================================================
# EC2 Instance Statuses
# ==============================================================================

# Instance Health Alarm
resource "aws_cloudwatch_metric_alarm" "instance_health_check" {
  count               = var.metric == "insthc" ? 1 : 0
  alarm_name          = "${local.name}-instance_health_check_failed"
  alarm_description   = "Instance status checks monitor the software and network configuration of your individual instance. When an instance status check fails, you typically must address the problem yourself: https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/monitoring-system-instance-status-check.html"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  metric_name         = "StatusCheckFailed_Instance"
  namespace           = "AWS/EC2"
  statistic           = "Average"

  evaluation_periods = var.eval_periods
  period             = var.period
  threshold          = var.threshold
  alarm_actions      = [var.topic]
  dimensions = {
    instanceId = tostring(local.instanceIds)
  }
}

# Status Check Alarm
resource "aws_cloudwatch_metric_alarm" "system_health_check" {
  count               = var.metric == "syshc" ? 1 : 0
  alarm_name          = "${local.name}-system_health_check_failed"
  alarm_description   = "System status checks monitor the AWS systems on which your instance runs. These checks detect underlying problems with your instance that require AWS involvement to repair: https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/monitoring-system-instance-status-check.html"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  metric_name         = "StatusCheckFailed_System"
  namespace           = "AWS/EC2"
  statistic           = "Average"

  evaluation_periods = var.eval_periods
  period             = var.period
  threshold          = var.threshold
  alarm_actions      = [var.topic]
  dimensions = {
    instanceId = tostring(local.instanceIds)
  }
}
