###############################################################
# Data Sources and CloudWatch Alarms for EC2 Instances Windows
###############################################################

#########################
# Data Sources Production
#########################

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

##############################
# CloudWatch Alarms Production
##############################

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

# Low Disk Alarms for all Windows instances with E, F, G and H Volumes
# Used for RGVW021, RGVW022, RGSW025 & RGVW027

locals {
  volume_alert_config = local.is-production ? {
    "i-00413756d2dfcf6d2" = {
      volumes = {
        "E:" = 5
      },
      ImageId      = "ami-0b8f6843db88aa8a6",
      InstanceType = "c5.4xlarge"
    },
    "i-080498c4c9d25e6bd" = {
      volumes = {
        "E:" = 5,
        "F:" = 5,
        "G:" = 5
      },
      ImageId      = "ami-05ddec53aa481cbc3",
      InstanceType = "m5.2xlarge"
    },
    "i-029d2b17679dab982" = {
      volumes = {
        "E:" = 0.5,
        "F:" = 0.5,
        "G:" = 0.5
      },
      ImageId      = "ami-02f8251c8cdf2464f",
      InstanceType = "m5.xlarge"
    },
    "i-00cbccc46d25e77c6" = {
      volumes = {
        "E:" = 1,
        "F:" = 2,
        "H:" = 1
      },
      ImageId      = "ami-0e203fec985af6465",
      InstanceType = "m5.xlarge"
    }
  } : {}
}

locals {
  volume_alarm_matrix = flatten([
    for instance_id, config in local.volume_alert_config : [
      for volume_letter, threshold in config.volumes : {
        key           = "${instance_id}-${volume_letter}"
        instance_id   = instance_id
        volume_letter = volume_letter
        threshold     = threshold
        ImageId       = config.ImageId
        InstanceType  = config.InstanceType
      }
    ]
  ])
  volume_alarm_map = {
    for item in local.volume_alarm_matrix :
    item.key => item
  }
}

resource "aws_cloudwatch_metric_alarm" "low_disk_space_EFGH_volume" {
  for_each            = local.is-production ? local.volume_alarm_map : {}
  alarm_name          = "Low-Disk-Space-${each.value.volume_letter}-Volume-${each.value.instance_id}"
  comparison_operator = "LessThanOrEqualToThreshold"
  evaluation_periods  = "5"
  datapoints_to_alarm = "5"
  metric_name         = "LogicalDisk % Free Space"
  namespace           = "CWAgent"
  period              = "60"
  statistic           = "Average"
  threshold           = each.value.threshold
  treat_missing_data  = "notBreaching"
  alarm_description   = "This metric monitors free disk space on ${each.value.volume_letter} of ${each.value.instance_id}. Alarm triggers below ${each.value.threshold}% for 5 minutes."
  alarm_actions       = [aws_sns_topic.cw_alerts[0].arn]
  dimensions = {
    InstanceId   = each.value.instance_id
    instance     = each.value.volume_letter
    ImageId      = each.value.ImageId
    InstanceType = each.value.InstanceType
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
  period              = "300"                               # period in seconds over which the specified statistic is applied
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

# IIS Status Check Alarm

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

# CloudWatch Alarms for Malware Events (Signature Update Failed, State Detected, Scan Failed, Engine Update Failed, Engine Out of Date & Behavior Detected)
/*
locals {
  malware_alarm_metadata_prod = local.is-production ? {
    MalwareScanFailed       = "Scan Failed"
    MalwareBehaviorDetected = "Behavior Detected"
    MalwareStateDetected    = "State Detected"
    MalwareSignatureFailed  = "Signature Failed"
    MalwareEngineFailed     = "Engine Failed"
    MalwareEngineOutofDate  = "Engine Out of Date"
  } : {}
}

locals {
  malware_alarm_matrix_prod = local.is-production ? tomap({
    for pair in flatten([
      for instance_id in data.aws_instances.windows_tagged_instances.ids : [
        for metric_name, description in local.malware_alarm_metadata_prod : {
          key = "${instance_id}-${metric_name}"
          value = {
            instance_id = instance_id
            metric_name = metric_name
            description = description
          }
        }
      ]
    ]) : pair.key => pair.value
  }) : {}
}

resource "aws_cloudwatch_metric_alarm" "malware_event_alarms_prod" {
  for_each = local.malware_alarm_matrix_prod

  alarm_name          = "Malware-Event-${each.value.metric_name}-${each.value.instance_id}"
  comparison_operator = "GreaterThanThreshold"
  period              = 60
  threshold           = 0
  evaluation_periods  = 1
  datapoints_to_alarm = 1
  metric_name         = each.value.metric_name
  namespace           = "WindowsDefender"
  statistic           = "Sum"
  treat_missing_data  = "notBreaching"
  alarm_description   = "Monitors for Windows Defender malware event: ${each.value.description}"
  alarm_actions       = [aws_sns_topic.cw_alerts[0].arn]

  dimensions = {
    Instance  = each.value.instance_id
    EventName = each.value.metric_name
  }
}
*/
# Service Status Alarms

# IIS Admin Service
/*
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
  metric_name         = "SQLBackupStatus"
  namespace           = "SQLBackup"
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
  metric_name         = "PortStatus"
  namespace           = "Port"
  period              = "60"
  statistic           = "Average"
  threshold           = "1"
  treat_missing_data  = "notBreaching"
  alarm_description   = "This metric monitors the port 25 status check to the internal mail relay (rgsl200). If the metric falls to 0 [unable to connect] then the alarm will trigger."
  alarm_actions       = [aws_sns_topic.cw_alerts[0].arn]
  dimensions = {
    Instance = "i-0dba6054c0f5f7a11"
    Port     = "Port25"
  }
}

resource "aws_cloudwatch_metric_alarm" "port_25_status_check_rgvw020" {
  count               = local.is-production == true ? 1 : 0
  alarm_name          = "Port-25-Status-Check-i-0f393d9ed4e53da68"
  comparison_operator = "LessThanThreshold"
  evaluation_periods  = "1"
  datapoints_to_alarm = "1"
  metric_name         = "PortStatus"
  namespace           = "Port"
  period              = "60"
  statistic           = "Average"
  threshold           = "1"
  treat_missing_data  = "notBreaching"
  alarm_description   = "This metric monitors the port 25 status check to the internal mail relay (rgsl200). If the metric falls to 0 [unable to connect] then the alarm will trigger."
  alarm_actions       = [aws_sns_topic.cw_alerts[0].arn]
  dimensions = {
    Instance = "i-0f393d9ed4e53da68"
    Port     = "Port25"
  }
}

resource "aws_cloudwatch_metric_alarm" "port_25_status_check_rgvw022" {
  count               = local.is-production == true ? 1 : 0
  alarm_name          = "Port-25-Status-Check-i-029d2b17679dab982"
  comparison_operator = "LessThanThreshold"
  evaluation_periods  = "1"
  datapoints_to_alarm = "1"
  metric_name         = "PortStatus"
  namespace           = "Port"
  period              = "60"
  statistic           = "Average"
  threshold           = "1"
  treat_missing_data  = "notBreaching"
  alarm_description   = "This metric monitors the port 25 status check to the internal mail relay (rgsl200). If the metric falls to 0 [unable to connect] then the alarm will trigger."
  alarm_actions       = [aws_sns_topic.cw_alerts[0].arn]
  dimensions = {
    Instance = "i-029d2b17679dab982"
    Port     = "Port25"
  }
}

resource "aws_cloudwatch_metric_alarm" "port_25_status_check_rgvw027" {
  count               = local.is-production == true ? 1 : 0
  alarm_name          = "Port-25-Status-Check-i-00cbccc46d25e77c6"
  comparison_operator = "LessThanThreshold"
  evaluation_periods  = "1"
  datapoints_to_alarm = "1"
  metric_name         = "PortStatus"
  namespace           = "Port"
  period              = "60"
  statistic           = "Average"
  threshold           = "1"
  treat_missing_data  = "notBreaching"
  alarm_description   = "This metric monitors the port 25 status check to the internal mail relay (rgsl200). If the metric falls to 0 [unable to connect] then the alarm will trigger."
  alarm_actions       = [aws_sns_topic.cw_alerts[0].arn]
  dimensions = {
    Instance = "i-00cbccc46d25e77c6"
    Port     = "Port25"
  }
}

# Email Sender Stale Log File

resource "aws_cloudwatch_metric_alarm" "emailsender_check_rgvw022" {
  count               = local.is-production == true ? 1 : 0
  alarm_name          = "Email-Sender-Check-i-029d2b17679dab982"
  comparison_operator = "LessThanThreshold"
  evaluation_periods  = "1"
  datapoints_to_alarm = "1"
  metric_name         = "EmailSenderStatus"
  namespace           = "EmailSender"
  period              = "3600"
  statistic           = "Average"
  threshold           = "1"
  treat_missing_data  = "notBreaching"
  alarm_description   = "Monitors for stale email sender log files "
  alarm_actions       = [aws_sns_topic.cw_alerts[0].arn]
  dimensions = {
    Instance    = "i-029d2b17679dab982"
    EmailSender = "EmailSender"
  }
}
*/

############################################################################
# CloudWatch Service, Port25 Check and EmailSender Check Alarms [Production]
############################################################################

# Data source to get all EC2 instances
data "aws_instances" "all_instances" {
  instance_state_names = ["running", "stopped"]
}

# Get instance details for each instance
data "aws_instance" "instance_details" {
  for_each    = toset(data.aws_instances.all_instances.ids)
  instance_id = each.value
}

# Create a map of instances with their tags for alarm creation
locals {
  # Filter instances that have monitoring tags and are in production
  instances_with_alarms = {
    for id, instance in data.aws_instance.instance_details :
    id => instance if lookup(instance.tags, "is-production", "false") == "true"
  }

  # Define alarm configurations
  alarm_configs = {
    iisadmin_service = {
      metric_name   = "IsRunning"
      namespace     = "ServiceStatus"
      service_name  = "IISADMIN"
      description   = "IIS Admin service"
      period        = "60"
    }
    wwwpub_service = {
      metric_name   = "IsRunning"
      namespace     = "ServiceStatus"
      service_name  = "W3SVC"
      description   = "World Wide Web Publishing service"
      period        = "60"
    }
    ppudlive_service = {
      metric_name   = "IsRunning"
      namespace     = "ServiceStatus"
      service_name  = "PPUDAutomatedProcessesLIVE"
      description   = "PPUD live service"
      period        = "60"
    }
    ppudcrawler_service = {
      metric_name   = "IsRunning"
      namespace     = "ServiceStatus"
      service_name  = "PPUDPDFCrawlerP4Live"
      description   = "PPUD crawler service"
      period        = "60"
    }
    spooler_service = {
      metric_name   = "IsRunning"
      namespace     = "ServiceStatus"
      service_name  = "Spooler"
      description   = "Printer Spooler service"
      period        = "60"
    }
    sqlserver_service = {
      metric_name   = "IsRunning"
      namespace     = "ServiceStatus"
      service_name  = "MSSQLSERVER"
      description   = "SQL Server service"
      period        = "60"
    }
    sqlwriter_service = {
      metric_name   = "IsRunning"
      namespace     = "ServiceStatus"
      service_name  = "SQLWriter"
      description   = "SQL Server VSS Writer service"
      period        = "60"
    }
    sqlagent_service = {
      metric_name   = "IsRunning"
      namespace     = "ServiceStatus"
      service_name  = "SQLServerAgent(MSSQLSERVER)"
      description   = "SQL Server Agent service"
      period        = "60"
    }
    sqlserver_backup = {
      metric_name   = "SQLBackupStatus"
      namespace     = "SQLBackup"
      service_name  = ""
      description   = "SQL Server backup status"
      period        = "60"
    }
    port25_check = {
      metric_name   = "PortStatus"
      namespace     = "Port"
      service_name  = "Port25"
      description   = "Port 25 status check to internal mail relay (rgsl200)"
      period        = "60"
    }
    emailsender_check = {
      metric_name   = "EmailSenderStatus"
      namespace     = "EmailSender"
      service_name  = "EmailSender"
      description   = "Email sender stale log files"
      period        = "3600"
    }
  }

  # Create alarm instances based on tags
  alarm_instances = flatten([
    for instance_id, instance in local.instances_with_alarms : [
      for tag_key, config in local.alarm_configs : {
        instance_id   = instance_id
        instance_name = lookup(instance.tags, "Name", instance_id)
        tag_key       = tag_key
        config        = config
      } if lookup(instance.tags, tag_key, "false") == "true"
    ]
  ])
}

# Create CloudWatch alarms dynamically
resource "aws_cloudwatch_metric_alarm" "service_alarms" {
  for_each = local.is-production ? {
    for alarm in local.alarm_instances :
    "${alarm.tag_key}_${alarm.instance_id}" => alarm
  } : {}
  alarm_name          = "${title(replace(each.value.tag_key, "_", "-"))}-${each.value.instance_id}"
  comparison_operator = "LessThanThreshold"
  evaluation_periods  = "1"
  datapoints_to_alarm = "1"
  metric_name         = each.value.config.metric_name
  namespace           = each.value.config.namespace
  period              = each.value.config.period
  statistic           = "Average"
  threshold           = "1"
  treat_missing_data  = "notBreaching"
  alarm_description   = "This metric monitors the ${each.value.config.description}. If the metric falls to 0 [not running] then the alarm will trigger."
  alarm_actions       = [aws_sns_topic.cw_alerts[0].arn]

  dimensions = merge(
    {
      Instance = each.value.instance_id
    },
    each.value.config.service_name != "" ? {
      Service = each.value.config.service_name
    } : {},
    each.value.tag_key == "port25_check" ? {
      Port = "Port25"
    } : {},
    each.value.tag_key == "emailsender_check" ? {
      EmailSender = "EmailSender"
    } : {}
  )
}

############################
# Data Sources PreProduction
############################

# Create a data source to fetch the tags of each instance
data "aws_instances" "windows_tagged_instances_uat" {
  filter {
    name   = "tag:patch_group"
    values = ["uat_win_patch"]
  }
}

# Data source for ImageId and InstanceType for each instance
data "aws_instance" "windows_instance_details_uat" {
  for_each    = toset(data.aws_instances.windows_tagged_instances_uat.ids)
  instance_id = each.value
}

# Create a data source to fetch the tags of each instance
data "aws_instances" "cpu_alarm_tagged_instances_uat" {
  filter {
    name   = "tag:cpu_alarm"
    values = ["true"]
  }
}

# Data source for individual instance details to access tags
data "aws_instance" "cpu_alarm_instance_details_uat" {
  for_each    = toset(data.aws_instances.cpu_alarm_tagged_instances_uat.ids)
  instance_id = each.value
}

#################################
# CloudWatch Alarms Preproduction
#################################

# CloudWatch Alarms for Malware Events (Signature Update Failed, State Detected, Scan Failed, Engine Update Failed, Engine Out of Date & Behavior Detected)
/*
locals {
  malware_alarm_metadata_preprod = local.is-preproduction ? {
    MalwareScanFailed       = "Scan Failed"
    MalwareBehaviorDetected = "Behavior Detected"
    MalwareStateDetected    = "State Detected"
    MalwareSignatureFailed  = "Signature Failed"
    MalwareEngineFailed     = "Engine Failed"
    MalwareEngineOutofDate  = "Engine Out of Date"
  } : {}
}

locals {
  malware_alarm_matrix_preprod = local.is-preproduction ? tomap({
    for pair in flatten([
      for instance_id in data.aws_instances.windows_tagged_instances_uat.ids : [
        for metric_name, description in local.malware_alarm_metadata_preprod : {
          key = "${instance_id}-${metric_name}"
          value = {
            instance_id = instance_id
            metric_name = metric_name
            description = description
          }
        }
      ]
    ]) : pair.key => pair.value
  }) : {}
}

resource "aws_cloudwatch_metric_alarm" "malware_event_alarms_preprod" {
  for_each = local.malware_alarm_matrix_preprod

  alarm_name          = "Malware-Event-${each.value.metric_name}-${each.value.instance_id}"
  comparison_operator = "GreaterThanThreshold"
  period              = 60
  threshold           = 0
  evaluation_periods  = 1
  datapoints_to_alarm = 1
  metric_name         = each.value.metric_name
  namespace           = "WindowsDefender"
  statistic           = "Sum"
  treat_missing_data  = "notBreaching"
  alarm_description   = "Monitors for Windows Defender malware event: ${each.value.description}"
  alarm_actions       = [aws_sns_topic.cw_uat_alerts[0].arn]

  dimensions = {
    Instance  = each.value.instance_id
    EventName = each.value.metric_name
  }
}
*/
# High CPU Utilization Alarm

resource "aws_cloudwatch_metric_alarm" "cpu_uat_alarms" {
  for_each            = toset(data.aws_instances.cpu_alarm_tagged_instances_uat.ids)
  alarm_name          = "CPU-Utilisation-High-${each.key}"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  period              = 300
  threshold           = 90
  evaluation_periods  = 3
  datapoints_to_alarm = 2
  metric_name         = "CPUUtilization"
  treat_missing_data  = "notBreaching"
  namespace           = "AWS/EC2"
  statistic           = "Average"
  alarm_description   = "Monitors EC2 CPU utilisation"

  alarm_actions = concat(
    [aws_sns_topic.cw_uat_alerts[0].arn],
    lookup(data.aws_instance.cpu_alarm_instance_details_uat[each.key].tags, "cpu_lambda_trigger", "false") == "true" && local.is-preproduction ?
    ["arn:aws:lambda:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:function:terminate_cpu_process_preproduction"] : []
  )

  dimensions = {
    InstanceId = each.key
  }
}

##########################
# Data Sources Development
##########################

# Create a data source to fetch the tags of each instance

data "aws_instances" "windows_tagged_instances_dev" {
  filter {
    name   = "tag:patch_group"
    values = ["dev_win_patch"]
  }
}

# Data source for ImageId and InstanceType for each instance

data "aws_instance" "windows_instance_details_dev" {
  for_each    = toset(data.aws_instances.windows_tagged_instances_dev.ids)
  instance_id = each.value
}

###############################
# CloudWatch Alarms Development
###############################
/*
# CloudWatch Alarms for Malware Events (Signature Update Failed, State Detected, Scan Failed, Engine Update Failed, Engine Out of Date & Behavior Detected)

locals {
  malware_alarm_metadata_dev = local.is-development ? {
    MalwareScanFailed       = "Scan Failed"
    MalwareBehaviorDetected = "Behavior Detected"
    MalwareStateDetected    = "State Detected"
    MalwareSignatureFailed  = "Signature Failed"
    MalwareEngineFailed     = "Engine Failed"
    MalwareEngineOutofDate  = "Engine Out of Date"
  } : {}
}

locals {
  malware_alarm_matrix_dev = local.is-development ? tomap({
    for pair in flatten([
      for instance_id in data.aws_instances.windows_tagged_instances_dev.ids : [
        for metric_name, description in local.malware_alarm_metadata_dev : {
          key = "${instance_id}-${metric_name}"
          value = {
            instance_id = instance_id
            metric_name = metric_name
            description = description
          }
        }
      ]
    ]) : pair.key => pair.value
  }) : {}
}

resource "aws_cloudwatch_metric_alarm" "malware_event_alarms_dev" {
  for_each = local.malware_alarm_matrix_dev

  alarm_name          = "Malware-Event-${each.value.metric_name}-${each.value.instance_id}"
  comparison_operator = "GreaterThanThreshold"
  period              = 60
  threshold           = 0
  evaluation_periods  = 1
  datapoints_to_alarm = 1
  metric_name         = each.value.metric_name
  namespace           = "WindowsDefender"
  statistic           = "Sum"
  treat_missing_data  = "notBreaching"
  alarm_description   = "Monitors for Windows Defender malware event: ${each.value.description}"
  alarm_actions       = [aws_sns_topic.cw_dev_alerts[0].arn]

  dimensions = {
    Instance  = each.value.instance_id
    EventName = each.value.metric_name
  }
}
*/

# CloudWatch Alarms for Malware Events (Signature Update Failed, State Detected, Scan Failed, Engine Update Failed, Engine Out of Date & Behavior Detected)

locals {
  malware_alarm_metadata = {
    MalwareScanFailed       = "Scan Failed"
    MalwareBehaviorDetected = "Behavior Detected"
    MalwareStateDetected    = "State Detected"
    MalwareSignatureFailed  = "Signature Failed"
    MalwareEngineFailed     = "Engine Failed"
    MalwareEngineOutofDate  = "Engine Out of Date"
  }

  malware_alarm_environments = {
    production = {
      enabled      = local.is-production
      instances    = data.aws_instances.windows_tagged_instances.ids
      sns_topic    = "arn:aws:sns:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:${local.application_data.accounts[local.environment].cloudwatch_sns_topic_name}"
    }
    preproduction = {
      enabled      = local.is-preproduction
      instances    = data.aws_instances.windows_tagged_instances_uat.ids
      sns_topic    = "arn:aws:sns:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:${local.application_data.accounts[local.environment].cloudwatch_sns_topic_name}"
    }
    development = {
      enabled      = local.is-development
      instances    = data.aws_instances.windows_tagged_instances_dev.ids
      sns_topic    = "arn:aws:sns:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:${local.application_data.accounts[local.environment].cloudwatch_sns_topic_name}"
    }
  }

  malware_alarm_matrix = tomap({
    for pair in flatten([
      for env_name, env_config in local.malware_alarm_environments : [
        for instance_id in env_config.instances : [
          for metric_name, description in local.malware_alarm_metadata : {
            key = "${env_name}-${instance_id}-${metric_name}"
            value = {
              env_name    = env_name
              instance_id = instance_id
              metric_name = metric_name
              description = description
              sns_topic   = env_config.sns_topic
            }
          } if env_config.enabled
        ] if env_config.enabled
      ]
    ]) : pair.key => pair.value
  })
}

resource "aws_cloudwatch_metric_alarm" "malware_event_alarms" {
  for_each = local.malware_alarm_matrix

  alarm_name          = "Malware-Event-${each.value.metric_name}-${each.value.instance_id}"
  comparison_operator = "GreaterThanThreshold"
  period              = 60
  threshold           = 0
  evaluation_periods  = 1
  datapoints_to_alarm = 1
  metric_name         = each.value.metric_name
  namespace           = "WindowsDefender"
  statistic           = "Sum"
  treat_missing_data  = "notBreaching"
  alarm_description   = "Monitors for Windows Defender malware event: ${each.value.description}"
  alarm_actions       = [each.value.sns_topic]

  dimensions = {
    Instance  = each.value.instance_id
    EventName = each.value.metric_name
  }
}
