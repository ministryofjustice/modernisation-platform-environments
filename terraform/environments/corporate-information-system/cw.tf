############# LOG GROUPS #############

##### EC2 Log Group

resource "aws_cloudwatch_log_group" "CISEC2LogGoup" {
  name              = "${local.application_name_short}-EC2"
  retention_in_days = 180
}

##### EC2 Cloudwatch Log Groups

resource "aws_cloudwatch_log_group" "CISLogGroupCfnInit" {
  name              = "${local.application_name_short}-CfnInit"
  retention_in_days = 180
}

resource "aws_cloudwatch_log_group" "CISLogGroupOracleAlerts" {
  name              = "${local.application_name_short}-OracleAlerts"
  retention_in_days = 180
}

resource "aws_cloudwatch_log_group" "CISLogGroupRman" {
  name              = "${local.application_name_short}-RMan"
  retention_in_days = 180

}

resource "aws_cloudwatch_log_group" "CISLogGroupRmanArch" {
  name              = "${local.application_name_short}-RManArch"
  retention_in_days = 180
}

resource "aws_cloudwatch_log_group" "CISLogGroupTBSFreespace" {
  name              = "${local.application_name_short}-TBSFreespace"
  retention_in_days = 180
}

resource "aws_cloudwatch_log_group" "CISLogGroupPMONstatus" {
  name              = "${local.application_name_short}-PMONstatus"
  retention_in_days = 180
}


############# ALARMS & FILTERS #############

resource "aws_cloudwatch_metric_alarm" "CISEc2CpuUtilisationTooHigh" {
  alarm_name          = "${local.application_name_short} | ${local.application_data.accounts[local.environment].cis_environment} | Database | EC2-CPU-High-Threshold-Alarm"
  alarm_description   = "The average CPU utilization is too high"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = local.application_data.accounts[local.environment].alert_evaluation_period
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = local.application_data.accounts[local.environment].alert_period
  statistic           = "Average"
  threshold           = local.application_data.accounts[local.environment].alert_threshold
  treat_missing_data  = "breaching"

  dimensions = {
    InstanceId = aws_instance.cis_db_instance.id
  }

  alarm_actions = [aws_sns_topic.cis_alerting_topic.arn]
  ok_actions    = [aws_sns_topic.cis_alerting_topic.arn]
}

resource "aws_cloudwatch_metric_alarm" "CISEc2MemoryOverThreshold" {
  alarm_name          = "${local.application_name_short} | ${local.application_data.accounts[local.environment].cis_environment} | Database | EC2-Memory-High-Threshold-Alarm"
  alarm_description   = "Average EC2 memory usage exceeds the predefined threshold"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = local.application_data.accounts[local.environment].alert_evaluation_period
  metric_name         = "mem_used_percent"
  namespace           = "CustomScript"
  period              = local.application_data.accounts[local.environment].alert_period
  statistic           = "Average"
  threshold           = local.application_data.accounts[local.environment].alert_threshold
  treat_missing_data  = "breaching"

  dimensions = {
    ImageId      = aws_instance.cis_db_instance.ami
    InstanceId   = aws_instance.cis_db_instance.id
    InstanceType = aws_instance.cis_db_instance.instance_type
  }

  alarm_actions = [aws_sns_topic.cis_alerting_topic.arn]
  ok_actions    = [aws_sns_topic.cis_alerting_topic.arn]
}

resource "aws_cloudwatch_metric_alarm" "CISEbsDiskSpaceUsedOverThreshold" {
  alarm_name          = "${local.application_name_short} | ${local.application_data.accounts[local.environment].cis_environment} | Database | EBS-DiskSpace-Alarm"
  alarm_description   = "EBS Volume - Disk Space is Low"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = local.application_data.accounts[local.environment].cis_diskspace_alert_evaluation_periods
  metric_name         = "disk_used_percent"
  namespace           = "CustomScript"
  period              = local.application_data.accounts[local.environment].alert_period
  statistic           = "Average"
  threshold           = local.application_data.accounts[local.environment].alert_threshold
  treat_missing_data  = "breaching"

  dimensions = {
    path         = local.application_data.accounts[local.environment].cis_disk_path
    InstanceId   = aws_instance.cis_db_instance.id
    ImageId      = aws_instance.cis_db_instance.ami
    InstanceType = aws_instance.cis_db_instance.instance_type
    device       = local.application_data.accounts[local.environment].cis_disk_device
    fstype       = local.application_data.accounts[local.environment].cis_disk_fs_type
  }

  alarm_actions = [aws_sns_topic.cis_alerting_topic.arn]
  ok_actions    = [aws_sns_topic.cis_alerting_topic.arn]
}

resource "aws_cloudwatch_metric_alarm" "CISLogRmanArchBackup" {
  alarm_name          = "${local.application_name_short} | ${local.application_data.accounts[local.environment].cis_environment} | Database | RManArch-LogErrors"
  alarm_description   = "Errors Detected in RMan Arch Log"
  metric_name         = "${local.application_name_short}_${local.application_data.accounts[local.environment].cis_log_metric_name_rman_arch_backup}"
  namespace           = "LogsMetricFilters"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  statistic           = "Sum"
  threshold           = local.application_data.accounts[local.environment].cis_logstream_errors_detected_threshold
  period              = local.application_data.accounts[local.environment].cis_logstream_errors_detected_periods
  evaluation_periods  = local.application_data.accounts[local.environment].cis_logstream_errors_detected_evaluation_periods
  treat_missing_data  = "notBreaching"

  alarm_actions = [aws_sns_topic.cis_alerting_topic.arn]
  ok_actions    = [aws_sns_topic.cis_alerting_topic.arn]
}

resource "aws_cloudwatch_log_metric_filter" "CISLogsMetricFilterRmanArchBackup" {
  name           = "CISLogsMetricFilterRmanArchBackup"
  log_group_name = aws_cloudwatch_log_group.CISLogGroupRmanArch.name
  pattern        = "?FAILURE ?Failure ?failure"

  metric_transformation {
    name      = "${local.application_name_short}_${local.application_data.accounts[local.environment].cis_log_metric_name_rman_arch_backup}"
    namespace = "LogsMetricFilters"
    value     = "1"
  }
}

resource "aws_cloudwatch_metric_alarm" "CISLogRmanBackup" {
  alarm_name          = "${local.application_name_short} | ${local.application_data.accounts[local.environment].cis_environment} | Database | RMan-LogErrors"
  alarm_description   = "Errors Detected in RMan Log"
  metric_name         = "${local.application_name_short}_${local.application_data.accounts[local.environment].cis_log_metric_name_rman_backup}"
  namespace           = "LogsMetricFilters"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  statistic           = "Sum"
  threshold           = local.application_data.accounts[local.environment].cis_logstream_errors_detected_threshold
  period              = local.application_data.accounts[local.environment].cis_logstream_errors_detected_periods
  evaluation_periods  = local.application_data.accounts[local.environment].cis_logstream_errors_detected_evaluation_periods
  treat_missing_data  = "notBreaching"

  alarm_actions = [aws_sns_topic.cis_alerting_topic.arn]
  ok_actions    = [aws_sns_topic.cis_alerting_topic.arn]
}

resource "aws_cloudwatch_log_metric_filter" "CISLogsMetricFilterRmanBackup" {
  name           = "CISLogsMetricFilterRmanBackup"
  log_group_name = aws_cloudwatch_log_group.CISLogGroupRman.name
  pattern        = "?ERRORs ?Errors ?errors ?ERROR ?Error ?error"

  metric_transformation {
    name      = "${local.application_name_short}_${local.application_data.accounts[local.environment].cis_log_metric_name_rman_backup}"
    namespace = "LogsMetricFilters"
    value     = "1"
  }
}

resource "aws_cloudwatch_metric_alarm" "CISLogPMONstatus" {
  alarm_name          = "${local.application_name_short} | ${local.application_data.accounts[local.environment].cis_environment} | Database | PMONstatus-LogErrors"
  alarm_description   = "Errors Detected in Oracle Alerts Log"
  metric_name         = "${local.application_name_short}_${local.application_data.accounts[local.environment].cis_log_metric_pmon_status}"
  namespace           = "LogsMetricFilters"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  statistic           = "Sum"
  threshold           = local.application_data.accounts[local.environment].cis_logstream_errors_detected_threshold
  period              = local.application_data.accounts[local.environment].cis_logstream_errors_detected_periods
  evaluation_periods  = local.application_data.accounts[local.environment].cis_logstream_errors_detected_evaluation_periods
  treat_missing_data  = "notBreaching"

  alarm_actions = [aws_sns_topic.cis_alerting_topic.arn]
  ok_actions    = [aws_sns_topic.cis_alerting_topic.arn]
}

resource "aws_cloudwatch_log_metric_filter" "CISLogsMetricFilterPMONstatus" {
  name           = "CISLogsMetricFilterPMONstatus"
  log_group_name = aws_cloudwatch_log_group.CISLogGroupPMONstatus.name
  pattern        = "DOWN"

  metric_transformation {
    name      = "${local.application_name_short}_${local.application_data.accounts[local.environment].cis_log_metric_pmon_status}"
    namespace = "LogsMetricFilters"
    value     = "1"
  }
}

resource "aws_cloudwatch_metric_alarm" "CISLogTBSFreespace" {
  alarm_name          = "${local.application_name_short} | ${local.application_data.accounts[local.environment].cis_environment} | Database | TBSFreespace-LogErrors"
  alarm_description   = "Errors Detected in Oracle Alerts Log"
  metric_name         = "${local.application_name_short}_${local.application_data.accounts[local.environment].cis_log_metrics_tbs_freespace}"
  namespace           = "LogsMetricFilters"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  statistic           = "Sum"
  threshold           = local.application_data.accounts[local.environment].cis_logstream_errors_detected_threshold
  period              = local.application_data.accounts[local.environment].cis_logstream_errors_detected_periods
  evaluation_periods  = local.application_data.accounts[local.environment].cis_logstream_errors_detected_evaluation_periods
  treat_missing_data  = "notBreaching"

  alarm_actions = [aws_sns_topic.cis_alerting_topic.arn]
  ok_actions    = [aws_sns_topic.cis_alerting_topic.arn]
}

resource "aws_cloudwatch_log_metric_filter" "CISLogsMetricFilterTBSFreespace" {
  name           = "CISLogsMetricFilterTBSFreespace"
  log_group_name = aws_cloudwatch_log_group.CISLogGroupTBSFreespace.name
  pattern        = "ALERT"

  metric_transformation {
    name      = "${local.application_name_short}_${local.application_data.accounts[local.environment].cis_log_metrics_tbs_freespace}"
    namespace = "LogsMetricFilters"
    value     = "1"
  }
}

resource "aws_cloudwatch_metric_alarm" "CISLogOracleAlerts" {
  alarm_name          = "${local.application_name_short} | ${local.application_data.accounts[local.environment].cis_environment} | Database OracleAlerts-LogErrors"
  alarm_description   = "Errors Detected in Oracle Alerts Log"
  metric_name         = "${local.application_name_short}-${local.application_data.accounts[local.environment].cis_log_metrics_oracle_alerts}"
  namespace           = "LogsMetricFilters"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  statistic           = "Sum"
  threshold           = local.application_data.accounts[local.environment].cis_logstream_errors_detected_threshold
  period              = local.application_data.accounts[local.environment].cis_logstream_errors_detected_periods
  evaluation_periods  = local.application_data.accounts[local.environment].cis_logstream_errors_detected_evaluation_periods
  treat_missing_data  = "notBreaching"

  alarm_actions = [aws_sns_topic.cis_alerting_topic.arn]
  ok_actions    = [aws_sns_topic.cis_alerting_topic.arn]
}

resource "aws_cloudwatch_log_metric_filter" "CISLogsMetricFilterOracleAlerts" {
  name           = "CISLogsMetricFilterOracleAlerts"
  log_group_name = aws_cloudwatch_log_group.CISLogGroupOracleAlerts.name
  pattern        = "\"ORA-\""

  metric_transformation {
    name      = "${local.application_name_short}_${local.application_data.accounts[local.environment].cis_log_metrics_oracle_alerts}"
    namespace = "LogsMetricFilters"
    value     = "1"
  }
}

############# DASHBOARDS #############

resource "aws_cloudwatch_dashboard" "cis-cloudwatch-dashboard" {
  dashboard_name = "${local.application_name_short}-${local.application_data.accounts[local.environment].cis_environment}-Database-Dashboard"
  dashboard_body = <<EOF
{
  "periodOverride": "inherit",
  "widgets": [
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
            "arn:aws:cloudwatch:${local.application_data.accounts[local.environment].cis_region}:${data.aws_caller_identity.current.account_id}:alarm:${aws_cloudwatch_metric_alarm.CISEc2CpuUtilisationTooHigh.arn}"
          ]
        },
        "view": "timeSeries",
        "legend": {
          "position": "hidden"
        },
        "period": ${local.application_data.accounts[local.environment].cis_dashboard_refresh_period},
        "region": "${local.application_data.accounts[local.environment].cis_region}",
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
            "arn:aws:cloudwatch:${local.application_data.accounts[local.environment].cis_region}:${data.aws_caller_identity.current.account_id}:alarm:${aws_cloudwatch_metric_alarm.CISEc2MemoryOverThreshold.arn}"
          ]
        },
        "view": "timeSeries",
        "legend": {
          "position": "hidden"
        },
        "period": ${local.application_data.accounts[local.environment].cis_dashboard_refresh_period},
        "region": "${local.application_data.accounts[local.environment].cis_region}",
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
            "arn:aws:cloudwatch:${local.application_data.accounts[local.environment].cis_region}:${data.aws_caller_identity.current.account_id}:alarm:${aws_cloudwatch_metric_alarm.CISEbsDiskSpaceUsedOverThreshold.arn}"
          ]
        },
        "view": "timeSeries",
        "legend": {
          "position": "hidden"
        },
        "period": ${local.application_data.accounts[local.environment].cis_dashboard_refresh_period},
        "region": "${local.application_data.accounts[local.environment].cis_region}",
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
        "title": "Resource Consumption",
        "alarms": [
          "arn:aws:cloudwatch:${local.application_data.accounts[local.environment].cis_region}:${data.aws_caller_identity.current.account_id}:alarm:${aws_cloudwatch_metric_alarm.CISEc2CpuUtilisationTooHigh.arn}",
          "arn:aws:cloudwatch:${local.application_data.accounts[local.environment].cis_region}:${data.aws_caller_identity.current.account_id}:alarm:${aws_cloudwatch_metric_alarm.CISEc2MemoryOverThreshold.arn}",
          "arn:aws:cloudwatch:${local.application_data.accounts[local.environment].cis_region}:${data.aws_caller_identity.current.account_id}:alarm:${aws_cloudwatch_metric_alarm.CISEbsDiskSpaceUsedOverThreshold.arn}"
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
          "arn:aws:cloudwatch:${local.application_data.accounts[local.environment].cis_region}:${data.aws_caller_identity.current.account_id}:alarm:${aws_cloudwatch_metric_alarm.CISLogOracleAlerts.arn}",
          "arn:aws:cloudwatch:${local.application_data.accounts[local.environment].cis_region}:${data.aws_caller_identity.current.account_id}:alarm:${aws_cloudwatch_metric_alarm.CISLogRmanBackup.arn}",
          "arn:aws:cloudwatch:${local.application_data.accounts[local.environment].cis_region}:${data.aws_caller_identity.current.account_id}:alarm:${aws_cloudwatch_metric_alarm.CISLogRmanArchBackup.arn}",
          "arn:aws:cloudwatch:${local.application_data.accounts[local.environment].cis_region}:${data.aws_caller_identity.current.account_id}:alarm:${aws_cloudwatch_metric_alarm.CISLogTBSFreespace.arn}",
          "arn:aws:cloudwatch:${local.application_data.accounts[local.environment].cis_region}:${data.aws_caller_identity.current.account_id}:alarm:${aws_cloudwatch_metric_alarm.CISLogPMONstatus.arn}"
        ]
      }
    }
  ]
}
EOF
}

############# SNS TOPIC #############

# SNS topic for monitoring to send alarms to
resource "aws_sns_topic" "cis_alerting_topic" {
  name = "${local.application_name_short}-SNS-topic"
  tags = merge(
    local.tags,
    {
      Name = "${local.application_name_short}-cis-alerting-topic"
    }
  )
}

# Pager duty integration

# Get the map of pagerduty integration keys from the modernisation platform account
data "aws_secretsmanager_secret" "cis_pagerduty_integration_keys" {
  provider = aws.modernisation-platform
  name     = "pagerduty_integration_keys"
}
data "aws_secretsmanager_secret_version" "cis_pagerduty_integration_keys" {
  provider  = aws.modernisation-platform
  secret_id = data.aws_secretsmanager_secret.cis_pagerduty_integration_keys.id
}

# Add a local to get the keys
locals {
  cis_pagerduty_integration_keys     = jsondecode(data.aws_secretsmanager_secret_version.cis_pagerduty_integration_keys.secret_string)
  cis_pagerduty_integration_key_name = local.application_data.accounts[local.environment].cis_pagerduty_integration_key_name
}

# link the sns topic to the service

module "cis_pagerduty_core_alerts" {
  depends_on = [
    aws_sns_topic.cis_alerting_topic
  ]
  source                    = "github.com/ministryofjustice/modernisation-platform-terraform-pagerduty-integration?ref=v2.0.0"
  sns_topics                = [aws_sns_topic.cis_alerting_topic.name]
  pagerduty_integration_key = local.cis_pagerduty_integration_keys[local.cis_pagerduty_integration_key_name]
}