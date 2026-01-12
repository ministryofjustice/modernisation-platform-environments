############# LOG GROUPS #############

##### EC2 Log Group

resource "aws_cloudwatch_log_group" "EC2LogGoup" {
  name              = "${local.application_name}-EC2"
  retention_in_days = 180
}

##### EC2 Cloudwatch Log Groups

resource "aws_cloudwatch_log_group" "EDWLogGroupCfnInit" {
  name              = "${local.application_name}-CfnInit"
  retention_in_days = 180
}

resource "aws_cloudwatch_log_group" "EDWLogGroupOracleAlerts" {
  name              = "${local.application_name}-OracleAlerts"
  retention_in_days = 180
}

resource "aws_cloudwatch_log_group" "EDWLogGroupRman" {
  name              = "${local.application_name}-RMan"
  retention_in_days = 180
}

resource "aws_cloudwatch_log_group" "EDWLogGroupRmanArch" {
  name              = "${local.application_name}-RManArch"
  retention_in_days = 180
}

resource "aws_cloudwatch_log_group" "EDWLogGroupTBSFreespace" {
  name              = "${local.application_name}-TBSFreespace"
  retention_in_days = 180
}

resource "aws_cloudwatch_log_group" "EDWLogGroupPMONstatus" {
  name              = "${local.application_name}-PMONstatus"
  retention_in_days = 180
}

resource "aws_cloudwatch_log_group" "EDWLogGroupCDCstatus" {
  name              = "${local.application_name}-CDCstatus"
  retention_in_days = 180
}

############# ALARMS & FILTERS #############

resource "aws_cloudwatch_metric_alarm" "EDWStatusCheckFailedInstance" {
  alarm_name          = "${local.application_name} | ${local.application_data.accounts[local.environment].edw_instance_descriptor} | StatusCheckFailed-Instance"
  alarm_description   = "Instance Status Check Failed"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = 1
  metric_name         = "StatusCheckFailed_Instance"
  namespace           = "AWS/EC2"
  period              = 60
  statistic           = "Sum"
  threshold           = 1

  dimensions = {
    InstanceId = aws_instance.edw_db_instance.id
  }
}

resource "aws_cloudwatch_metric_alarm" "EDWStatusCheckFailed" {
  alarm_name          = "${local.application_name} | ${local.application_data.accounts[local.environment].edw_instance_descriptor} | StatusCheckFailed"
  alarm_description   = "Status Check Failed"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = 1
  metric_name         = "StatusCheckFailed"
  namespace           = "AWS/EC2"
  period              = 60
  statistic           = "Sum"
  threshold           = 1

  dimensions = {
    InstanceId = aws_instance.edw_db_instance.id
  }
}

resource "aws_cloudwatch_metric_alarm" "EDWEc2CpuUtilisationTooHigh" {
  alarm_name          = "${local.application_name} | ${local.application_data.accounts[local.environment].edw_environment} | ${local.application_data.accounts[local.environment].edw_instance_descriptor} | EC2-CPU-High-Threshold-Alarm"
  alarm_description   = "The average CPU utilization is too high"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = local.application_data.accounts[local.environment].edw_cpu_evaluation_period
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = local.application_data.accounts[local.environment].edw_cpu_alert_period
  statistic           = "Average"
  threshold           = local.application_data.accounts[local.environment].edw_cpu_alert_threshold
  treat_missing_data  = "breaching"

  dimensions = {
    InstanceId = aws_instance.edw_db_instance.id
  }
}

resource "aws_cloudwatch_metric_alarm" "EDWEc2MemoryOverThreshold" {
  alarm_name          = "${local.application_name} | ${local.application_data.accounts[local.environment].edw_environment} | ${local.application_data.accounts[local.environment].edw_instance_descriptor} | EC2-Memory-High-Threshold-Alarm"
  alarm_description   = "Average EC2 memory usage exceeds the predefined threshold"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = local.application_data.accounts[local.environment].edw_mem_alert_evaluation_periods
  metric_name         = "mem_used_percent"
  namespace           = "CustomScript"
  period              = local.application_data.accounts[local.environment].edw_mem_alert_period
  statistic           = "Average"
  threshold           = local.application_data.accounts[local.environment].edw_mem_alert_threshold
  treat_missing_data  = "breaching"

  dimensions = {
    ImageId      = aws_instance.edw_db_instance.ami
    InstanceId   = aws_instance.edw_db_instance.id
    InstanceType = aws_instance.edw_db_instance.instance_type
  }
}

resource "aws_cloudwatch_metric_alarm" "EDWEbsDiskSpaceUsedOverThreshold" {
  alarm_name          = "${local.application_name} | ${local.application_data.accounts[local.environment].edw_environment} | ${local.application_data.accounts[local.environment].edw_instance_descriptor} | EBS-DiskSpace-Alarm"
  alarm_description   = "EBS Volume - Disk Space is Low"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = local.application_data.accounts[local.environment].edw_diskspace_alert_evaluation_periods
  metric_name         = "disk_used_percent"
  namespace           = "CustomScript"
  period              = local.application_data.accounts[local.environment].edw_diskspace_alert_period
  statistic           = "Average"
  threshold           = local.application_data.accounts[local.environment].edw_diskspace_alert_threshold
  treat_missing_data  = "breaching"

  dimensions = {
    path         = local.application_data.accounts[local.environment].edw_disk_path
    InstanceId   = aws_instance.edw_db_instance.id
    ImageId      = aws_instance.edw_db_instance.ami
    InstanceType = aws_instance.edw_db_instance.instance_type
    device       = local.application_data.accounts[local.environment].edw_disk_device
    fstype       = local.application_data.accounts[local.environment].edw_disk_fs_type
  }
}

############# LOG METRIC FILTERS #############


############# DASHBOARDS #############

resource "aws_cloudwatch_dashboard" "edw-cloudwatch-dashboard" {
  dashboard_name = "${local.application_name}-${local.application_data.accounts[local.environment].edw_environment}-${local.application_data.accounts[local.environment].edw_instance_descriptor}-Dashboard"

  dashboard_body = <<EOF
{
  "periodOverride": "inherit",
  "widgets": []
}
EOF
}