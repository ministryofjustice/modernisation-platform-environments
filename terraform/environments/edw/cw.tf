############# LOG GROUPS #############

##### EC2 Log Group

resource "aws_cloudwatch_log_group" "EC2LogGoup" {
  name                 = "${local.application_name}-EC2"
  retention_in_days    = 180
  retention_in_days    = 180
  # DeletionPolicy and UpdateReplacePolicy are not directly supported in the AWS provider for Terraform.
  # However, you can manually handle retention and retention policies in the AWS console or CLI.
}

##### EC2 Cloudwatch Log Groups

resource "aws_cloudwatch_log_group" "LogGroupCfnInit" {
  name                 = "${local.application_name}-CfnInit"
  retention_in_days    = 180
  # DeletionPolicy and UpdateReplacePolicy are not directly supported in the AWS provider for Terraform.
  # However, you can manually handle retention and retention policies in the AWS console or CLI.
}

resource "aws_cloudwatch_log_group" "LogGroupOracleAlerts" {
  name                 = "${local.application_name}-OracleAlerts"
  retention_in_days    = 180
  # DeletionPolicy and UpdateReplacePolicy are not directly supported in the AWS provider for Terraform.
  # However, you can manually handle retention and retention policies in the AWS console or CLI.
}

resource "aws_cloudwatch_log_group" "LogGroupRman" {
  name                 = "${local.application_name}-RMan"
  retention_in_days    = 180
  # DeletionPolicy and UpdateReplacePolicy are not directly supported in the AWS provider for Terraform.
  # However, you can manually handle retention and retention policies in the AWS console or CLI.
}

resource "aws_cloudwatch_log_group" "LogGroupRmanArch" {
  name                 = "${local.application_name}-RManArch"
  retention_in_days    = 180
  # DeletionPolicy and UpdateReplacePolicy are not directly supported in the AWS provider for Terraform.
  # However, you can manually handle retention and retention policies in the AWS console or CLI.
}

resource "aws_cloudwatch_log_group" "LogGroupTBSFreespace" {
  name                 = "${local.application_name}-TBSFreespace"
  retention_in_days    = 180
  # DeletionPolicy and UpdateReplacePolicy are not directly supported in the AWS provider for Terraform.
  # However, you can manually handle retention and retention policies in the AWS console or CLI.
}

resource "aws_cloudwatch_log_group" "LogGroupPMONstatus" {
  name                 = "${local.application_name}-PMONstatus"
  retention_in_days    = 180
  # DeletionPolicy and UpdateReplacePolicy are not directly supported in the AWS provider for Terraform.
  # However, you can manually handle retention and retention policies in the AWS console or CLI.
}

resource "aws_cloudwatch_log_group" "LogGroupCDCstatus" {
  name                 = "${local.application_name}-CDCstatus"
  retention_in_days    = 180
  # DeletionPolicy and UpdateReplacePolicy are not directly supported in the AWS provider for Terraform.
  # However, you can manually handle retention and retention policies in the AWS console or CLI.
}


############# ALARMS #############

resource "aws_cloudwatch_metric_alarm" "rStatusCheckFailedInstance" {
  alarm_name          = "${local.application_name} | ${var.InstanceDescriptor} | StatusCheckFailed-Instance"
  alarm_description   = "Instance Status Check Failed"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = 1
  metric_name         = "StatusCheckFailed_Instance"
  namespace           = "AWS/EC2"
  period              = 60
  statistic           = "Sum"
  threshold           = 1

  dimensions = {
    InstanceId = aws_instance.DBInstance.id
  }

  alarm_actions = [local.application_data.accounts[local.environment].edw_sns_topic_arn]
  ok_actions    = [local.application_data.accounts[local.environment].edw_sns_topic_arn]
}

resource "aws_cloudwatch_metric_alarm" "rStatusCheckFailed" {
  alarm_name          = "${local.application_name} | ${var.InstanceDescriptor} | StatusCheckFailed"
  alarm_description   = "Status Check Failed"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = 1
  metric_name         = "StatusCheckFailed"
  namespace           = "AWS/EC2"
  period              = 60
  statistic           = "Sum"
  threshold           = 1

  dimensions = {
    InstanceId = aws_instance.DBInstance.id
  }

  alarm_actions = [local.application_data.accounts[local.environment].edw_sns_topic_arn]
  ok_actions    = [local.application_data.accounts[local.environment].edw_sns_topic_arn]
}

resource "aws_cloudwatch_metric_alarm" "rEc2CpuUtilisationTooHigh" {
  alarm_name          = "${local.application_name} | ${local.application_data.accounts[local.environment].edw_environment} | ${var.InstanceDescriptor} | EC2-CPU-High-Threshold-Alarm"
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
    InstanceId = aws_instance.DBInstance.id
  }

  alarm_actions = [local.application_data.accounts[local.environment].edw_sns_topic_arn]
  ok_actions    = [local.application_data.accounts[local.environment].edw_sns_topic_arn]
}

resource "aws_cloudwatch_metric_alarm" "rEc2MemoryOverThreshold" {
  alarm_name          = "${local.application_name} | ${local.application_data.accounts[local.environment].edw_environment} | ${var.InstanceDescriptor} | EC2-Memory-High-Threshold-Alarm"
  alarm_description   = "Average EC2 memory usage exceeds the predefined threshold"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = local.application_data.accounts[local.environment].edw_mem_alert_evaluation_periods
  metric_name         = "mem_used_percent"
  namespace           = var.MetricsSuppliedBy
  period              = local.application_data.accounts[local.environment].edw_mem_alert_period
  statistic           = "Average"
  threshold           = local.application_data.accounts[local.environment].edw_mem_alert_threshold
  treat_missing_data  = "breaching"

  dimensions = {
    ImageId     = aws_instance.DBInstance.ami
    InstanceId  = aws_instance.DBInstance.id
    InstanceType = aws_instance.DBInstance.instance_type
  }

  alarm_actions = [local.application_data.accounts[local.environment].edw_sns_topic_arn]
  ok_actions    = [local.application_data.accounts[local.environment].edw_sns_topic_arn]
}

resource "aws_cloudwatch_metric_alarm" "rEbsDiskSpaceUsedOverThreshold" {
  alarm_name          = "${local.application_name} | ${local.application_data.accounts[local.environment].edw_environment} | ${var.InstanceDescriptor} | EBS-DiskSpace-Alarm"
  alarm_description   = "EBS Volume - Disk Space is Low"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = local.application_data.accounts[local.environment].edw_diskspace_alert_evaluation_periods
  metric_name         = "disk_used_percent"
  namespace           = var.MetricsSuppliedBy
  period              = local.application_data.accounts[local.environment].edw_diskspace_alert_period
  statistic           = "Average"
  threshold           = local.application_data.accounts[local.environment].edw_diskspace_alert_threshold
  treat_missing_data  = "breaching"

  dimensions = {
    path     = local.application_data.accounts[local.environment].edw_disk_path
    InstanceId = aws_instance.DBInstance.id
    ImageId = aws_instance.DBInstance.ami
    InstanceType = aws_instance.DBInstance.instance_type
    device = local.application_data.accounts[local.environment].edw_disk_device
    fstype = local.application_data.accounts[local.environment].edw_disk_fs_type
  }

  alarm_actions = [local.application_data.accounts[local.environment].edw_sns_topic_arn]
  ok_actions    = [local.application_data.accounts[local.environment].edw_sns_topic_arn]
}

resource "aws_cloudwatch_metric_alarm" "rOradataQueueLengthOverThreshold" {
  alarm_name          = "${local.application_name} | ${var.InstanceDescriptor} | Oradata-Queue-Length"
  alarm_description   = "Oradata Volume EBS Queue Length is High"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 1
  metric_name         = "VolumeQueueLength"
  namespace           = var.MetricsSuppliedBy
  period              = 60
  statistic           = "Average"
  threshold           = 3

  dimensions = {
    VolumeId = aws_ebs_volume.oradataVolume.id
  }

  alarm_actions = [local.application_data.accounts[local.environment].edw_sns_topic_arn]
  ok_actions    = [local.application_data.accounts[local.environment].edw_sns_topic_arn]
}

resource "aws_cloudwatch_metric_alarm" "rLogStreamErrorsAlarmTBSFreespace" {
  alarm_name          = "${local.application_name} | ${local.application_data.accounts[local.environment].edw_environment} | ${var.InstanceDescriptor} | TBSFreespace-LogErrors"
  alarm_description   = "Errors Detected in Oracle Alerts Log"
  metric_name         = "${local.application_name}_${local.application_data.accounts[local.environment].edw_log_metrics_tbs_freespace}"
  namespace           = local.application_data.accounts[local.environment].edw_log_metric_filter_namespace
  comparison_operator = "GreaterThanOrEqualToThreshold"
  statistic           = "Sum"
  threshold           = var.LogStreamErrorsDetectedThreshold
  period              = local.application_data.accounts[local.environment].edw_logstream_errors_detected_periods
  evaluation_periods  = local.application_data.accounts[local.environment].edw_logstream_errors_detected_evaluation_periods
  treat_missing_data  = "notBreaching"

  alarm_actions = [local.application_data.accounts[local.environment].edw_sns_topic_arn]
  ok_actions    = [local.application_data.accounts[local.environment].edw_sns_topic_arn]
}

resource "aws_cloudwatch_metric_alarm" "rLogStreamErrorsAlarmPMONstatus" {
  alarm_name          = "${local.application_name} | ${local.application_data.accounts[local.environment].edw_environment} | ${var.InstanceDescriptor} | PMONstatus-LogErrors"
  alarm_description   = "Errors Detected in Oracle Alerts Log"
  metric_name         = "${local.application_name}_${local.application_data.accounts[local.environment].edw_log_metric_pmon_status}"
  namespace           = local.application_data.accounts[local.environment].edw_log_metric_filter_namespace
  comparison_operator = "GreaterThanOrEqualToThreshold"
  statistic           = "Sum"
  threshold           = var.LogStreamErrorsDetectedThreshold
  period              = local.application_data.accounts[local.environment].edw_logstream_errors_detected_periods
  evaluation_periods  = local.application_data.accounts[local.environment].edw_logstream_errors_detected_evaluation_periods
  treat_missing_data  = "notBreaching"

  alarm_actions = [local.application_data.accounts[local.environment].edw_sns_topic_arn]
  ok_actions    = [local.application_data.accounts[local.environment].edw_sns_topic_arn]
}

resource "aws_cloudwatch_metric_alarm" "rLogStreamErrorsAlarmCDCstatus" {
  alarm_name          = "${local.application_name} | ${local.application_data.accounts[local.environment].edw_environment} | ${var.InstanceDescriptor} | CDCApplytatus-LogErrors"
  alarm_description   = "Errors Detected in Oracle CDC Log"
  metric_name         = "${local.application_name}_${var.local.application_data.accounts[local.environment].edw_log_metric_cdc_status}"
  namespace           = local.application_data.accounts[local.environment].edw_log_metric_filter_namespace
  comparison_operator = "GreaterThanOrEqualToThreshold"
  statistic           = "Sum"
  threshold           = var.LogStreamErrorsDetectedThreshold
  period              = local.application_data.accounts[local.environment].edw_logstream_errors_detected_periods
  evaluation_periods  = local.application_data.accounts[local.environment].edw_logstream_errors_detected_evaluation_periods
  treat_missing_data  = "notBreaching"

  alarm_actions = [local.application_data.accounts[local.environment].edw_sns_topic_arn]
  ok_actions    = [local.application_data.accounts[local.environment].edw_sns_topic_arn]
}

resource "aws_cloudwatch_metric_alarm" "rLogStreamErrorsAlarmCDCstatus2" {
  alarm_name          = "${local.application_name} | ${local.application_data.accounts[local.environment].edw_environment} | ${var.InstanceDescriptor} | CDCSourcestatus-LogErrors"
  alarm_description   = "Errors Detected in Oracle CDC Log"
  metric_name         = "${local.application_name}_${var.local.application_data.accounts[local.environment].edw_log_metric_cdc_status2}"
  namespace           = local.application_data.accounts[local.environment].edw_log_metric_filter_namespace
  comparison_operator = "GreaterThanOrEqualToThreshold"
  statistic           = "Sum"
  threshold           = var.LogStreamErrorsDetectedThreshold
  period              = local.application_data.accounts[local.environment].edw_logstream_errors_detected_periods
  evaluation_periods  = local.application_data.accounts[local.environment].edw_logstream_errors_detected_evaluation_periods
  treat_missing_data  = "notBreaching"

  alarm_actions = [local.application_data.accounts[local.environment].edw_sns_topic_arn]
  ok_actions    = [local.application_data.accounts[local.environment].edw_sns_topic_arn]
}

resource "aws_cloudwatch_metric_alarm" "rLogStreamErrorsAlarmRmanBackup" {
  alarm_name          = "${local.application_name} | ${local.application_data.accounts[local.environment].edw_environment} | ${var.InstanceDescriptor} | RMan-LogErrors"
  alarm_description   = "Errors Detected in RMan Log"
  metric_name         = "${local.application_name}_${var.LogMetricNameRmanBackup}"
  namespace           = local.application_data.accounts[local.environment].edw_log_metric_filter_namespace
  comparison_operator = "GreaterThanOrEqualToThreshold"
  statistic           = "Sum"
  threshold           = var.LogStreamErrorsDetectedThreshold
  period              = local.application_data.accounts[local.environment].edw_logstream_errors_detected_periods
  evaluation_periods  = local.application_data.accounts[local.environment].edw_logstream_errors_detected_evaluation_periods
  treat_missing_data  = "notBreaching"

  alarm_actions = [local.application_data.accounts[local.environment].edw_sns_topic_arn]
  ok_actions    = [local.application_data.accounts[local.environment].edw_sns_topic_arn]
}

resource "aws_cloudwatch_metric_alarm" "rLogStreamErrorsAlarmRmanArchBackup" {
  alarm_name          = "${local.application_name} | ${local.application_data.accounts[local.environment].edw_environment} | ${var.InstanceDescriptor} | RManArch-LogErrors"
  alarm_description   = "Errors Detected in RMan Arch Log"
  metric_name         = "${local.application_name}_${local.application_data.accounts[local.environment].edw_log_metric_name_rman_arch_backup}"
  namespace           = local.application_data.accounts[local.environment].edw_log_metric_filter_namespace
  comparison_operator = "GreaterThanOrEqualToThreshold"
  statistic           = "Sum"
  threshold           = var.LogStreamErrorsDetectedThreshold
  period              = local.application_data.accounts[local.environment].edw_logstream_errors_detected_periods
  evaluation_periods  = local.application_data.accounts[local.environment].edw_logstream_errors_detected_evaluation_periods
  treat_missing_data  = "notBreaching"

  alarm_actions = [local.application_data.accounts[local.environment].edw_sns_topic_arn]
  ok_actions    = [local.application_data.accounts[local.environment].edw_sns_topic_arn]
}


############# FILTERS #############

resource "aws_cloudwatch_metric_filter" "rLogsMetricFilterRmanArchBackup" {
  name           = "rLogsMetricFilterRmanArchBackup"
  log_group_name = aws_cloudwatch_log_group.LogGroupNameRmanArchBackup.name
  filter_pattern = var.RmanArchLogMetricFilterPattern

  metric_transformation {
    name      = "${local.application_name}_${local.application_data.accounts[local.environment].edw_log_metric_name_rman_arch_backup}"
    namespace = local.application_data.accounts[local.environment].edw_log_metric_filter_namespace
    value     = "1"
  }
}

resource "aws_cloudwatch_metric_filter" "rLogsMetricFilterOracleAlerts" {
  name           = "rLogsMetricFilterOracleAlerts"
  log_group_name = aws_cloudwatch_log_group.LogGroupNameOracleAlerts.name
  filter_pattern = var.OracleAlertsLogMetricFilterPattern

  metric_transformation {
    name      = "${local.application_name}_${local.application_data.accounts[local.environment].edw_log_metrics_oracle_alerts}"
    namespace = local.application_data.accounts[local.environment].edw_log_metric_filter_namespace
    value     = "1"
  }
}

resource "aws_cloudwatch_metric_filter" "rLogsMetricFilterTBSFreespace" {
  name           = "rLogsMetricFilterTBSFreespace"
  log_group_name = aws_cloudwatch_log_group.LogGroupNameTBSFreespace.name
  filter_pattern = var.TBSFreespaceLogMetricFilterPattern

  metric_transformation {
    name      = "${local.application_name}_${local.application_data.accounts[local.environment].edw_log_metrics_tbs_freespace}"
    namespace = local.application_data.accounts[local.environment].edw_log_metric_filter_namespace
    value     = "1"
  }
}

resource "aws_cloudwatch_metric_filter" "rLogsMetricFilterPMONstatus" {
  name           = "rLogsMetricFilterPMONstatus"
  log_group_name = aws_cloudwatch_log_group.LogGroupNamePMONstatus.name
  filter_pattern = var.PMONstatusLogMetricFilterPattern

  metric_transformation {
    name      = "${local.application_name}_${local.application_data.accounts[local.environment].edw_log_metric_pmon_status}"
    namespace = local.application_data.accounts[local.environment].edw_log_metric_filter_namespace
    value     = "1"
  }
}

resource "aws_cloudwatch_metric_filter" "rLogsMetricFilterCDCstatus" {
  name           = "rLogsMetricFilterCDCstatus"
  log_group_name = aws_cloudwatch_log_group.LogGroupNameCDCstatus.name
  filter_pattern = var.CDCstatusLogMetricFilterPattern

  metric_transformation {
    name      = "${local.application_name}_${var.local.application_data.accounts[local.environment].edw_log_metric_cdc_status}"
    namespace = local.application_data.accounts[local.environment].edw_log_metric_filter_namespace
    value     = "1"
  }
}

resource "aws_cloudwatch_metric_filter" "rLogsMetricFilterCDCstatus2" {
  name           = "rLogsMetricFilterCDCstatus2"
  log_group_name = aws_cloudwatch_log_group.LogGroupNameCDCstatus.name
  filter_pattern = var.CDCstatusLogMetricFilterPattern2

  metric_transformation {
    name      = "${local.application_name}_${var.local.application_data.accounts[local.environment].edw_log_metric_cdc_status2}"
    namespace = local.application_data.accounts[local.environment].edw_log_metric_filter_namespace
    value     = "1"
  }
}

resource "aws_cloudwatch_metric_filter" "rLogsMetricFilterRmanBackup" {
  name           = "rLogsMetricFilterRmanBackup"
  log_group_name = aws_cloudwatch_log_group.LogGroupNameRmanBackup.name
  filter_pattern = var.RmanLogMetricFilterPattern

  metric_transformation {
    name      = "${local.application_name}_${var.LogMetricNameRmanBackup}"
    namespace = local.application_data.accounts[local.environment].edw_log_metric_filter_namespace
    value     = "1"
  }
}


############# DASHBOARDS #############

resource "aws_cloudwatch_dashboard" "rCloudwatchDashboard" {
  dashboard_name = "${local.application_name}-${local.application_data.accounts[local.environment].pEnvironment}-${local.application_data.accounts[local.environment].edw_instance_descriptor}-Dashboard"
  dashboard_body = <<EOF
{
  "periodOverride": "inherit",
  "widgets": [
    {
      "type": "metric",
      "x": 0,
      "y": 0,
      "height": 5,
      "width": 8,
      "properties": {
        "title": "EC2 Status Check Failure",
        "annotations": {
          "alarms": [
            "arn:aws:cloudwatch:${local.application_data.accounts[local.environment].edw_region}:${data.aws_caller_identity.current.account_id}:alarm:${aws_cloudwatch_metric_alarm.rStatusCheckFailed.arn}"
          ]
        },
        "view": "timeSeries",
        "legend": {
          "position": "hidden"
        },
        "period": ${local.application_data.accounts[local.environment].edw_dashboard_refresh_period},
        "region": "${local.application_data.accounts[local.environment].edw_region}",
        "stacked": true
      }
    },
    {
      "type": "metric",
      "x": 8,
      "y": 0,
      "height": 5,
      "width": 8,
      "properties": {
        "title": "EC2 Status Check Failure- Instance",
        "annotations": {
          "alarms": [
            "arn:aws:cloudwatch:${local.application_data.accounts[local.environment].edw_region}:${data.aws_caller_identity.current.account_id}:alarm:${aws_cloudwatch_metric_alarm.rStatusCheckFailedInstance.arn}"
          ]
        },
        "view": "timeSeries",
        "legend": {
          "position": "hidden"
        },
        "period": ${local.application_data.accounts[local.environment].edw_dashboard_refresh_period},
        "region": "${local.application_data.accounts[local.environment].edw_region}",
        "stacked": true
      }
    },
    {
      "type": "metric",
      "x": 0,
      "y": 5,
      "height": 5,
      "width": 8,
      "properties": {
        "title": "EC2 CPU Usage",
        "annotations": {
          "alarms": [
            "arn:aws:cloudwatch:${local.application_data.accounts[local.environment].edw_region}:${data.aws_caller_identity.current.account_id}:alarm:${aws_cloudwatch_metric_alarm.rEc2CpuUtilisationTooHigh.arn}"
          ]
        },
        "view": "timeSeries",
        "legend": {
          "position": "hidden"
        },
        "period": ${local.application_data.accounts[local.environment].edw_dashboard_refresh_period},
        "region": "${local.application_data.accounts[local.environment].edw_region}",
        "stacked": true
      }
    },
    {
      "type": "metric",
      "x": 8,
      "y": 5,
      "height": 5,
      "width": 8,
      "properties": {
        "title": "EC2 Memory Usage",
        "annotations": {
          "alarms": [
            "arn:aws:cloudwatch:${local.application_data.accounts[local.environment].edw_region}:${data.aws_caller_identity.current.account_id}:alarm:${aws_cloudwatch_metric_alarm.rEc2MemoryOverThreshold.arn}"
          ]
        },
        "view": "timeSeries",
        "legend": {
          "position": "hidden"
        },
        "period": ${local.application_data.accounts[local.environment].edw_dashboard_refresh_period},
        "region": "${local.application_data.accounts[local.environment].edw_region}",
        "stacked": true
      }
    },
    {
      "type": "metric",
      "x": 16,
      "y": 5,
      "height": 5,
      "width": 8,
      "properties": {
        "title": "EBS Disk Usage",
        "annotations": {
          "alarms": [
            "arn:aws:cloudwatch:${local.application_data.accounts[local.environment].edw_region}:${data.aws_caller_identity.current.account_id}:alarm:${aws_cloudwatch_metric_alarm.rEbsDiskSpaceUsedOverThreshold.arn}"
          ]
        },
        "view": "timeSeries",
        "legend": {
          "position": "hidden"
        },
        "period": ${local.application_data.accounts[local.environment].edw_dashboard_refresh_period},
        "region": "${local.application_data.accounts[local.environment].edw_region}",
        "stacked": true
      }
    },
    {
      "type": "alarm",
      "x": 0,
      "y": 10,
      "width": 8,
      "height": 5,
      "properties": {
        "title": "Status Check Failures",
        "alarms": [
          "arn:aws:cloudwatch:${local.application_data.accounts[local.environment].edw_region}:${data.aws_caller_identity.current.account_id}:alarm:${aws_cloudwatch_metric_alarm.rStatusCheckFailed.arn}",
          "arn:aws:cloudwatch:${local.application_data.accounts[local.environment].edw_region}:${data.aws_caller_identity.current.account_id}:alarm:${aws_cloudwatch_metric_alarm.rStatusCheckFailedInstance.arn}"
        ]
      }
    },
    {
      "type": "alarm",
      "x": 0,
      "y": 10,
      "width": 8,
      "height": 5,
      "properties": {
        "title": "Resource Consumption",
        "alarms": [
          "arn:aws:cloudwatch:${local.application_data.accounts[local.environment].edw_region}:${data.aws_caller_identity.current.account_id}:alarm:${aws_cloudwatch_metric_alarm.rEc2CpuUtilisationTooHigh.arn}",
          "arn:aws:cloudwatch:${local.application_data.accounts[local.environment].edw_region}:${data.aws_caller_identity.current.account_id}:alarm:${aws_cloudwatch_metric_alarm.rEc2MemoryOverThreshold.arn}",
          "arn:aws:cloudwatch:${local.application_data.accounts[local.environment].edw_region}:${data.aws_caller_identity.current.account_id}:alarm:${aws_cloudwatch_metric_alarm.rEbsDiskSpaceUsedOverThreshold.arn}"
        ]
      }
    },
    {
      "type": "alarm",
      "x": 8,
      "y": 10,
      "width": 8,
      "height": 5,
      "properties": {
        "title": "Oracle Log Errors",
        "alarms": [
          "arn:aws:cloudwatch:${local.application_data.accounts[local.environment].edw_region}:${data.aws_caller_identity.current.account_id}:alarm:${aws_cloudwatch_metric_alarm.rLogStreamErrorsAlarmOracleAlerts.arn}",
          "arn:aws:cloudwatch:${local.application_data.accounts[local.environment].edw_region}:${data.aws_caller_identity.current.account_id}:alarm:${aws_cloudwatch_metric_alarm.rLogStreamErrorsAlarmRmanBackup.arn}",
          "arn:aws:cloudwatch:${local.application_data.accounts[local.environment].edw_region}:${data.aws_caller_identity.current.account_id}:alarm:${aws_cloudwatch_metric_alarm.rLogStreamErrorsAlarmRmanArchBackup.arn}",
          "arn:aws:cloudwatch:${local.application_data.accounts[local.environment].edw_region}:${data.aws_caller_identity.current.account_id}:alarm:${aws_cloudwatch_metric_alarm.rLogStreamErrorsAlarmTBSFreespace.arn}",
          "arn:aws:cloudwatch:${local.application_data.accounts[local.environment].edw_region}:${data.aws_caller_identity.current.account_id}:alarm:${aws_cloudwatch_metric_alarm.rLogStreamErrorsAlarmPMONstatus.arn}"
        ]
      }
    }
  ]
}
EOF
}
