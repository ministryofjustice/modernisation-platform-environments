############# LOG GROUPS #############

##### EC2 Log Group

resource "aws_cloudwatch_log_group" "EC2LogGoup" {
  name                 = "${local.application_name}-EC2"
  retention_in_days    = 180
}

##### EC2 Cloudwatch Log Groups

resource "aws_cloudwatch_log_group" "EDWLogGroupCfnInit" {
  name                 = "${local.application_name}-CfnInit"
  retention_in_days    = 180
}

resource "aws_cloudwatch_log_group" "EDWLogGroupOracleAlerts" {
  name                 = "${local.application_name}-OracleAlerts"
  retention_in_days    = 180
}

resource "aws_cloudwatch_log_group" "EDWLogGroupRman" {
  name                 = "${local.application_name}-RMan"
  retention_in_days    = 180

}

resource "aws_cloudwatch_log_group" "EDWLogGroupRmanArch" {
  name                 = "${local.application_name}-RManArch"
  retention_in_days    = 180
}

resource "aws_cloudwatch_log_group" "EDWLogGroupTBSFreespace" {
  name                 = "${local.application_name}-TBSFreespace"
  retention_in_days    = 180
}

resource "aws_cloudwatch_log_group" "EDWLogGroupPMONstatus" {
  name                 = "${local.application_name}-PMONstatus"
  retention_in_days    = 180
}

resource "aws_cloudwatch_log_group" "EDWLogGroupCDCstatus" {
  name                 = "${local.application_name}-CDCstatus"
  retention_in_days    = 180
}


############# ALARMS & FILTERS #############

resource "aws_cloudwatch_metric_alarm" "EDWStatusCheckFailedInstance" {
  alarm_name          = "${local.application_name} | Database | StatusCheckFailed-Instance"
  alarm_description   = "Instance Status Check Failed"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = "1"
  metric_name         = "StatusCheckFailed_Instance"
  namespace           = "AWS/EC2"
  period              = "60"
  statistic           = "Sum"
  threshold           = "1"

  dimensions = {
    InstanceId = aws_instance.edw_db_instance.id
  }

  alarm_actions = [aws_sns_topic.edw_alerting_topic.arn]
  ok_actions    = [aws_sns_topic.edw_alerting_topic.arn]
}

resource "aws_cloudwatch_metric_alarm" "EDWStatusCheckFailed" {
  alarm_name          = "${local.application_name} | Database | StatusCheckFailed"
  alarm_description   = "Status Check Failed"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = "1"
  metric_name         = "StatusCheckFailed"
  namespace           = "AWS/EC2"
  period              = "1"
  statistic           = "Sum"
  threshold           = "0"

  dimensions = {
    InstanceId = aws_instance.edw_db_instance.id
  }

  alarm_actions = [aws_sns_topic.edw_alerting_topic.arn]
  ok_actions    = [aws_sns_topic.edw_alerting_topic.arn]
}

resource "aws_cloudwatch_metric_alarm" "EDWEc2CpuUtilisationTooHigh" {
  alarm_name          = "${local.application_name} | ${local.application_data.accounts[local.environment].edw_environment} | Database | EC2-CPU-High-Threshold-Alarm"
  alarm_description   = "The average CPU utilization is too high"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = "1"
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = "1"
  statistic           = "Average"
  threshold           = "1"
  treat_missing_data  = "breaching"

  dimensions = {
    InstanceId = aws_instance.edw_db_instance.id
  }

  alarm_actions = [aws_sns_topic.edw_alerting_topic.arn]
  ok_actions    = [aws_sns_topic.edw_alerting_topic.arn]
}

resource "aws_cloudwatch_metric_alarm" "EDWEc2MemoryOverThreshold" {
  alarm_name          = "${local.application_name} | ${local.application_data.accounts[local.environment].edw_environment} | Database | EC2-Memory-High-Threshold-Alarm"
  alarm_description   = "Average EC2 memory usage exceeds the predefined threshold"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = "5"
  metric_name         = "mem_used_percent"
  namespace           = "CustomScript"
  period              = "60"
  statistic           = "Average"
  threshold           = "90"
  treat_missing_data  = "breaching"

  dimensions = {
    ImageId     = aws_instance.edw_db_instance.ami
    InstanceId  = aws_instance.edw_db_instance.id
    InstanceType = aws_instance.edw_db_instance.instance_type
  }

  alarm_actions = [aws_sns_topic.edw_alerting_topic.arn]
  ok_actions    = [aws_sns_topic.edw_alerting_topic.arn]
}

resource "aws_cloudwatch_metric_alarm" "EDWEbsDiskSpaceUsedOverThreshold" {
  alarm_name          = "${local.application_name} | ${local.application_data.accounts[local.environment].edw_environment} | Database | EBS-DiskSpace-Alarm"
  alarm_description   = "EBS Volume - Disk Space is Low"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = "1"
  metric_name         = "disk_used_percent"
  namespace           = "CustomScript"
  period              = "60"
  statistic           = "Average"
  threshold           = "90"
  treat_missing_data  = "breaching"

  dimensions = {
    path     = local.application_data.accounts[local.environment].edw_disk_path
    InstanceId = aws_instance.edw_db_instance.id
    ImageId = aws_instance.edw_db_instance.ami
    InstanceType = aws_instance.edw_db_instance.instance_type
    device = local.application_data.accounts[local.environment].edw_disk_device
    fstype = local.application_data.accounts[local.environment].edw_disk_fs_type
  }
 
  alarm_actions = [aws_sns_topic.edw_alerting_topic.arn]
  ok_actions    = [aws_sns_topic.edw_alerting_topic.arn]
}

resource "aws_cloudwatch_metric_alarm" "EDWOradataQueueLengthOverThreshold" {
  alarm_name          = "${local.application_name} | Database | Oradata-Queue-Length"
  alarm_description   = "Oradata Volume EBS Queue Length is High"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "1"
  metric_name         = "VolumeQueueLength"
  namespace           = "CustomScript"
  period              = "60"
  statistic           = "Average"
  threshold           = "3"

  dimensions = {
    VolumeId = aws_ebs_volume.oradataVolume.id
  }

  alarm_actions = [aws_sns_topic.edw_alerting_topic.arn]
  ok_actions    = [aws_sns_topic.edw_alerting_topic.arn]
}

resource "aws_cloudwatch_metric_alarm" "EDWLogStreamErrorsAlarmOracleAlerts" {
  alarm_name          = "${local.application_name} | ${local.application_data.accounts[local.environment].edw_environment} | Database OracleAlerts-LogErrors"
  alarm_description   = "Errors Detected in Oracle Alerts Log"
  metric_name         = "${local.application_name}-oracle_alert_log_errors"
  namespace           = "LogsMetricFilters"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  statistic           = "Sum"
  threshold           = "1"
  period              = "3600"
  evaluation_periods  = "1"
  treat_missing_data  = "notBreaching"

  alarm_actions       = [aws_sns_topic.edw_alerting_topic.arn]
  ok_actions          = [aws_sns_topic.edw_alerting_topic.arn]
}

resource "aws_cloudwatch_log_metric_filter" "EDWLogsMetricFilterOracleAlerts" {
  name           = "EDWLogsMetricFilterOracleAlerts"
  log_group_name = aws_cloudwatch_log_group.EDWLogGroupOracleAlerts.name
  pattern = "\"ORA-\""

  metric_transformation {
    name      = "${local.application_name}_oracle_alert_log_errors"
    namespace = "LogsMetricFilters"
    value     = "1"
  }
}

resource "aws_cloudwatch_metric_alarm" "EDWLogStreamErrorsAlarmTBSFreespace" {
  alarm_name          = "${local.application_name} | ${local.application_data.accounts[local.environment].edw_environment} | Database | TBSFreespace-LogErrors"
  alarm_description   = "Errors Detected in Oracle Alerts Log"
  metric_name         = "${local.application_name}_db_tablespace_space_alerts"
  namespace           = "LogsMetricFilters"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  statistic           = "Sum"
  threshold           = "1"
  period              = "3600"
  evaluation_periods  = "1"
  treat_missing_data  = "notBreaching"

  alarm_actions = [aws_sns_topic.edw_alerting_topic.arn]
  ok_actions    = [aws_sns_topic.edw_alerting_topic.arn]
}

resource "aws_cloudwatch_log_metric_filter" "EDWLogsMetricFilterTBSFreespace" {
  name           = "EDWLogsMetricFilterTBSFreespace"
  log_group_name = aws_cloudwatch_log_group.EDWLogGroupTBSFreespace.name
  pattern = "ALERT"

  metric_transformation {
    name      = "${local.application_name}_db_tablespace_space_alerts"
    namespace = "LogsMetricFilters"
    value     = "1"
  }
}

resource "aws_cloudwatch_metric_alarm" "EDWLogStreamErrorsAlarmPMONstatus" {
  alarm_name          = "${local.application_name} | ${local.application_data.accounts[local.environment].edw_environment} | Database | PMONstatus-LogErrors"
  alarm_description   = "Errors Detected in Oracle Alerts Log"
  metric_name         = "${local.application_name}_db_PMON_status_alerts"
  namespace           = "LogsMetricFilters"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  statistic           = "Sum"
  threshold           = "1"
  period              = "3600"
  evaluation_periods  = "1"
  treat_missing_data  = "notBreaching"

  alarm_actions = [aws_sns_topic.edw_alerting_topic.arn]
  ok_actions    = [aws_sns_topic.edw_alerting_topic.arn]
}

resource "aws_cloudwatch_log_metric_filter" "EDWLogsMetricFilterPMONstatus" {
  name           = "EDWLogsMetricFilterPMONstatus"
  log_group_name = aws_cloudwatch_log_group.EDWLogGroupPMONstatus.name
  pattern = "DOWN"

  metric_transformation {
    name      = "${local.application_name}_db_PMON_status_alerts"
    namespace = "LogsMetricFilters"
    value     = "1"
  }
}

resource "aws_cloudwatch_metric_alarm" "EDWLogStreamErrorsAlarmCDCstatus" {
  alarm_name          = "${local.application_name} | ${local.application_data.accounts[local.environment].edw_environment} | Database | CDCApplytatus-LogErrors"
  alarm_description   = "Errors Detected in Oracle CDC Log"
  metric_name         = "${local.application_name}_db_CDC_status_alerts"
  namespace           = "LogsMetricFilters"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  statistic           = "Sum"
  threshold           = "1"
  period              = "3600"
  evaluation_periods  = "1"
  treat_missing_data  = "notBreaching"

  alarm_actions = [aws_sns_topic.edw_alerting_topic.arn]
  ok_actions    = [aws_sns_topic.edw_alerting_topic.arn]
}

resource "aws_cloudwatch_log_metric_filter" "EDWLogsMetricFilterCDCstatus" {
  name           = "EDWLogsMetricFilterCDCstatus"
  log_group_name = aws_cloudwatch_log_group.EDWLogGroupCDCstatus.name
  pattern =  "[APPLY_NAME, STATUS=\"DISABLED\"]"

  metric_transformation {
    name      = "${local.application_name}_db_CDC_status_alerts"
    namespace = "LogsMetricFilters"
    value     = "1"
  }
}

resource "aws_cloudwatch_metric_alarm" "EDWLogStreamErrorsAlarmCDCstatus2" {
  alarm_name          = "${local.application_name} | ${local.application_data.accounts[local.environment].edw_environment} | Database | CDCSourcestatus-LogErrors"
  alarm_description   = "Errors Detected in Oracle CDC Log"
  metric_name         = "${local.application_name}_db_CDC_Applystatus_alerts"
  namespace           = "LogsMetricFilters"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  statistic           = "Sum"
  threshold           = "1"
  period              = "3600"
  evaluation_periods  = "1"
  treat_missing_data  = "notBreaching"

  alarm_actions = [aws_sns_topic.edw_alerting_topic.arn]
  ok_actions    = [aws_sns_topic.edw_alerting_topic.arn]
}

resource "aws_cloudwatch_log_metric_filter" "EDWLogsMetricFilterCDCstatus2" {
  name           = "EDWLogsMetricFilterCDCstatus2"
  log_group_name = aws_cloudwatch_log_group.EDWLogGroupCDCstatus.name
  pattern = "[SOURCE_NAME ,SOURCE_ENABLED=\"N\"]"

  metric_transformation {
    name      = "${local.application_name}_db_CDC_Applystatus_alerts"
    namespace = "LogsMetricFilters"
    value     = "1"
  }
}

resource "aws_cloudwatch_metric_alarm" "EDWLogStreamErrorsAlarmRmanBackup" {
  alarm_name          = "${local.application_name} | ${local.application_data.accounts[local.environment].edw_environment} | Database | RMan-LogErrors"
  alarm_description   = "Errors Detected in RMan Log"
  metric_name         = "${local.application_name}_rman_backup_log_errors"
  namespace           = "LogsMetricFilters"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  statistic           = "Sum"
  threshold           = "1"
  period              = "3600"
  evaluation_periods  = "1"
  treat_missing_data  = "notBreaching"

  alarm_actions = [aws_sns_topic.edw_alerting_topic.arn]
  ok_actions    = [aws_sns_topic.edw_alerting_topic.arn]
}

resource "aws_cloudwatch_log_metric_filter" "EDWLogsMetricFilterRmanBackup" {
  name           = "EDWLogsMetricFilterRmanBackup"
  log_group_name = aws_cloudwatch_log_group.EDWLogGroupRman.name
  pattern = "?ERRORs ?Errors ?errors ?ERROR ?Error ?error"

  metric_transformation {
    name      = "${local.application_name}_rman_backup_log_errors"
    namespace = "LogsMetricFilters"
    value     = "1"
  }
}

resource "aws_cloudwatch_metric_alarm" "EDWLogStreamErrorsAlarmRmanArchBackup" {
  alarm_name          = "${local.application_name} | ${local.application_data.accounts[local.environment].edw_environment} | Database | RManArch-LogErrors"
  alarm_description   = "Errors Detected in RMan Arch Log"
  metric_name         = "${local.application_name}_rman_arch_backup_log_errors"
  namespace           = "LogsMetricFilters"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  statistic           = "Sum"
  threshold           = "1"
  period              = "3600"
  evaluation_periods  = "1"
  treat_missing_data  = "notBreaching"

  alarm_actions = [aws_sns_topic.edw_alerting_topic.arn]
  ok_actions    = [aws_sns_topic.edw_alerting_topic.arn]
}

resource "aws_cloudwatch_log_metric_filter" "EDWLogsMetricFilterRmanArchBackup" {
  name           = "EDWLogsMetricFilterRmanArchBackup"
  log_group_name = aws_cloudwatch_log_group.EDWLogGroupRmanArch.name
  pattern = "?FAILURE ?Failure ?failure"

  metric_transformation {
    name      = "${local.application_name}_rman_arch_backup_log_errors"
    namespace = "LogsMetricFilters"
    value     = "1"
  }
}


############# DASHBOARDS #############

resource "aws_cloudwatch_dashboard" "edw-cloudwatch-dashboard" {
  dashboard_name = "${local.application_name}-${local.application_data.accounts[local.environment].edw_environment}-Database-Dashboard"
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
            "arn:aws:cloudwatch:${local.application_data.accounts[local.environment].edw_region}:${data.aws_caller_identity.current.account_id}:alarm:${aws_cloudwatch_metric_alarm.EDWStatusCheckFailed.arn}"
          ]
        },
        "view": "timeSeries",
        "legend": {
          "position": "hidden"
        },
        "period": "60",
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
            "arn:aws:cloudwatch:${local.application_data.accounts[local.environment].edw_region}:${data.aws_caller_identity.current.account_id}:alarm:${aws_cloudwatch_metric_alarm.EDWStatusCheckFailedInstance.arn}"
          ]
        },
        "view": "timeSeries",
        "legend": {
          "position": "hidden"
        },
        "period": "60",
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
            "arn:aws:cloudwatch:${local.application_data.accounts[local.environment].edw_region}:${data.aws_caller_identity.current.account_id}:alarm:${aws_cloudwatch_metric_alarm.EDWEc2CpuUtilisationTooHigh.arn}"
          ]
        },
        "view": "timeSeries",
        "legend": {
          "position": "hidden"
        },
        "period": "60",
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
            "arn:aws:cloudwatch:${local.application_data.accounts[local.environment].edw_region}:${data.aws_caller_identity.current.account_id}:alarm:${aws_cloudwatch_metric_alarm.EDWEc2MemoryOverThreshold.arn}"
          ]
        },
        "view": "timeSeries",
        "legend": {
          "position": "hidden"
        },
        "period": "60",
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
            "arn:aws:cloudwatch:${local.application_data.accounts[local.environment].edw_region}:${data.aws_caller_identity.current.account_id}:alarm:${aws_cloudwatch_metric_alarm.EDWEbsDiskSpaceUsedOverThreshold.arn}"
          ]
        },
        "view": "timeSeries",
        "legend": {
          "position": "hidden"
        },
        "period": "60",
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
          "arn:aws:cloudwatch:${local.application_data.accounts[local.environment].edw_region}:${data.aws_caller_identity.current.account_id}:alarm:${aws_cloudwatch_metric_alarm.EDWStatusCheckFailed.arn}",
          "arn:aws:cloudwatch:${local.application_data.accounts[local.environment].edw_region}:${data.aws_caller_identity.current.account_id}:alarm:${aws_cloudwatch_metric_alarm.EDWStatusCheckFailedInstance.arn}"
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
          "arn:aws:cloudwatch:${local.application_data.accounts[local.environment].edw_region}:${data.aws_caller_identity.current.account_id}:alarm:${aws_cloudwatch_metric_alarm.EDWEc2CpuUtilisationTooHigh.arn}",
          "arn:aws:cloudwatch:${local.application_data.accounts[local.environment].edw_region}:${data.aws_caller_identity.current.account_id}:alarm:${aws_cloudwatch_metric_alarm.EDWEc2MemoryOverThreshold.arn}",
          "arn:aws:cloudwatch:${local.application_data.accounts[local.environment].edw_region}:${data.aws_caller_identity.current.account_id}:alarm:${aws_cloudwatch_metric_alarm.EDWEbsDiskSpaceUsedOverThreshold.arn}"
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
          "arn:aws:cloudwatch:${local.application_data.accounts[local.environment].edw_region}:${data.aws_caller_identity.current.account_id}:alarm:${aws_cloudwatch_metric_alarm.EDWLogStreamErrorsAlarmOracleAlerts.arn}",
          "arn:aws:cloudwatch:${local.application_data.accounts[local.environment].edw_region}:${data.aws_caller_identity.current.account_id}:alarm:${aws_cloudwatch_metric_alarm.EDWLogStreamErrorsAlarmRmanBackup.arn}",
          "arn:aws:cloudwatch:${local.application_data.accounts[local.environment].edw_region}:${data.aws_caller_identity.current.account_id}:alarm:${aws_cloudwatch_metric_alarm.EDWLogStreamErrorsAlarmRmanArchBackup.arn}",
          "arn:aws:cloudwatch:${local.application_data.accounts[local.environment].edw_region}:${data.aws_caller_identity.current.account_id}:alarm:${aws_cloudwatch_metric_alarm.EDWLogStreamErrorsAlarmTBSFreespace.arn}",
          "arn:aws:cloudwatch:${local.application_data.accounts[local.environment].edw_region}:${data.aws_caller_identity.current.account_id}:alarm:${aws_cloudwatch_metric_alarm.EDWLogStreamErrorsAlarmPMONstatus.arn}"
        ]
      }
    }
  ]
}
EOF
}

# ############# CLOUDFORMATION STACK #############

# resource "aws_cloudformation_stack" "edw-cloudwatch-stack" {
#   name          = "${local.application_name}-cloudwatch-stack"
#   capabilities = ["CAPABILITY_IAM"]
  
#   tags = merge(
#     local.tags,
#     {
#       Name = "${local.application_name}-edw-cloudwatch-stack"
#     }
#   )  
# }

############# SNS TOPIC #############

# SNS topic for monitoring to send alarms to
resource "aws_sns_topic" "edw_alerting_topic" {
  name = "${local.application_name}-SNS-topic"
  tags = merge(
    local.tags,
    {
      Name = "${local.application_name}-edw-alerting-topic"
    }
  )
}

# Pager duty integration

# Get the map of pagerduty integration keys from the modernisation platform account
data "aws_secretsmanager_secret" "edw_pagerduty_integration_keys" {
  provider = aws.modernisation-platform
  name     = "pagerduty_integration_keys"
}
data "aws_secretsmanager_secret_version" "edw_pagerduty_integration_keys" {
  provider  = aws.modernisation-platform
  secret_id = data.aws_secretsmanager_secret.edw_pagerduty_integration_keys.id
}

# Add a local to get the keys
locals {
  edw_pagerduty_integration_keys     = jsondecode(data.aws_secretsmanager_secret_version.edw_pagerduty_integration_keys.secret_string)
  edw_pagerduty_integration_key_name = local.application_data.accounts[local.environment].edw_pagerduty_integration_key_name
}

# link the sns topic to the service

module "edw_pagerduty_core_alerts" {
  depends_on = [
    aws_sns_topic.edw_alerting_topic
  ]
  source                    = "github.com/ministryofjustice/modernisation-platform-terraform-pagerduty-integration?ref=v2.0.0"
  sns_topics                = [aws_sns_topic.edw_alerting_topic.name]
  pagerduty_integration_key = local.edw_pagerduty_integration_keys[local.edw_pagerduty_integration_key_name]
}