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

######################################################################
# CloudWatch Health, System Check, CPU, Memory, Disk Alarms Production
######################################################################

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

# Data source to get all EC2 instances
data "aws_instances" "disk_instances" {
  instance_state_names = ["running", "stopped"]
}

# Get instance details for each instance
data "aws_instance" "disk_instance_details" {
  for_each    = toset(data.aws_instances.disk_instances.ids)
  instance_id = each.value
}

locals {
  # Filter instances that have volume tags and are in production
  instances_with_volumes = {
    for id, instance in data.aws_instance.disk_instance_details :
    id => instance if lookup(instance.tags, "is-production", "false") == "true"
  }

  # Define volume thresholds per instance based on current configuration
  volume_thresholds = {
    # Database Server (rgvw021)
    "ami-05ddec53aa481cbc3" = {
      "E:" = 5
      "F:" = 5
      "G:" = 5
    }
    # Primary Doc Server (rgvw022)
    "ami-02f8251c8cdf2464f" = {
      "E:" = 0.5
      "F:" = 0.5
      "G:" = 0.5
    }
    # WAM Data Access Server (rgsw025)
    "ami-0b8f6843db88aa8a6" = {
      "E:" = 5
    }
    # Secondary Doc Server (rgvw027)
    "ami-0e203fec985af6465" = {
      "E:" = 1
      "F:" = 2
      "H:" = 1
    }
  }

  # Create volume alarm instances based on tags and AMI
  volume_alarm_instances = flatten([
    for instance_id, instance in local.instances_with_volumes : [
      for volume_tag in ["e_volume", "f_volume", "g_volume", "h_volume"] : {
        instance_id   = instance_id
        instance_name = lookup(instance.tags, "Name", instance_id)
        ami_id        = instance.ami
        instance_type = instance.instance_type
        volume_letter = upper(substr(volume_tag, 0, 1))
        volume_tag    = volume_tag
        threshold = lookup(
          lookup(local.volume_thresholds, instance.ami, {}),
          "${upper(substr(volume_tag, 0, 1))}:",
          1 # default threshold
        )
      } if lookup(instance.tags, volume_tag, "false") == "true"
    ]
  ])
}

# Create CloudWatch disk space alarms dynamically
resource "aws_cloudwatch_metric_alarm" "low_disk_space_EFGH_volumes" {
  for_each = local.is-production ? {
    for alarm in local.volume_alarm_instances :
    "${alarm.volume_tag}_${alarm.instance_id}" => alarm
  } : {}

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
  alarm_description   = "This metric monitors free disk space on ${each.value.volume_letter}: of ${each.value.instance_id}. Alarm triggers below ${each.value.threshold}% for 5 minutes."
  alarm_actions       = [aws_sns_topic.cw_alerts[0].arn]

  dimensions = {
    InstanceId   = each.value.instance_id
    instance     = "${each.value.volume_letter}:"
    ImageId      = each.value.ami_id
    InstanceType = each.value.instance_type
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

resource "aws_cloudwatch_metric_alarm" "cpu_utilization" {
  for_each            = toset(data.aws_instances.windows_tagged_instances.ids)
  alarm_name          = "CPU-Utilisation-High-${each.key}" # name of the alarm
  comparison_operator = "GreaterThanOrEqualToThreshold"    # threshold to trigger the alarm state
  period              = "300"                              # period in seconds over which the specified statistic is applied
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
  alarm_actions       = [aws_sns_topic.cw_std_and_sms_alerts[0].arn]
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
  alarm_actions       = [aws_sns_topic.cw_std_and_sms_alerts[0].arn]
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
      alarm_name   = "Service-Status-IISAdmin"
      metric_name  = "IsRunning"
      namespace    = "ServiceStatus"
      service_name = "IISAdminService"
      description  = "IIS Admin service"
      period       = "60"
    }
    wwwpub_service = {
      alarm_name   = "Service-Status-WWW-Publishing"
      metric_name  = "IsRunning"
      namespace    = "ServiceStatus"
      service_name = "WorldWideWebPublishingService"
      description  = "World Wide Web Publishing service"
      period       = "60"
    }
    ppudlive_service = {
      alarm_name   = "Service-Status-PPUD-Live"
      metric_name  = "IsRunning"
      namespace    = "ServiceStatus"
      service_name = "PPUDAutomatedProcessesLIVE"
      description  = "PPUD live service"
      period       = "60"
    }
    ppudcrawler_service = {
      alarm_name   = "Service-Status-PPUD-Crawler"
      metric_name  = "IsRunning"
      namespace    = "ServiceStatus"
      service_name = "PPUDPDFCrawlerP4Live"
      description  = "PPUD crawler service"
      period       = "60"
    }
    spooler_service = {
      alarm_name   = "Service-Status-Printer-Spooler"
      metric_name  = "IsRunning"
      namespace    = "ServiceStatus"
      service_name = "PrintSpooler"
      description  = "Printer Spooler service"
      period       = "60"
    }
    sqlserver_service = {
      alarm_name   = "Service-Status-SQL-Server"
      metric_name  = "IsRunning"
      namespace    = "ServiceStatus"
      service_name = "SQLServer(MSSQLSERVER)"
      description  = "SQL Server service"
      period       = "60"
    }
    sqlwriter_service = {
      alarm_name   = "Service-Status-SQL-Server-Writer"
      metric_name  = "IsRunning"
      namespace    = "ServiceStatus"
      service_name = "SQLServerVSSWriter"
      description  = "SQL Server VSS Writer service"
      period       = "60"
    }
    sqlagent_service = {
      alarm_name   = "Service-Status-SQL-Server-Agent"
      metric_name  = "IsRunning"
      namespace    = "ServiceStatus"
      service_name = "SQLServerAgent(MSSQLSERVER)"
      description  = "SQL Server Agent service"
      period       = "60"
    }
    sqlserver_backup = {
      alarm_name   = "Service-Status-SQL-Server-Backup-Status"
      metric_name  = "SQLBackupStatus"
      namespace    = "SQLBackup"
      service_name = ""
      description  = "SQL Server backup status"
      period       = "60"
    }
    port25_check = {
      alarm_name   = "Port-25-Status-Check"
      metric_name  = "PortStatus"
      namespace    = "Port"
      service_name = ""
      description  = "Port 25 status check to internal mail relay (rgsl200)"
      period       = "60"
    }
    emailsender_check = {
      alarm_name   = "Email-Sender-Check"
      metric_name  = "EmailSenderStatus"
      namespace    = "EmailSender"
      service_name = ""
      description  = "Email sender stale log files"
      period       = "3600"
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
  alarm_name          = "${each.value.config.alarm_name}-${each.value.instance_id}"
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
  alarm_actions       = [aws_sns_topic.cw_std_and_sms_alerts[0].arn]

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

######################################
# CloudWatch CPU Alarms [Preroduction]
######################################

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

###################################################
# CloudWatch Malware Events Alarms All Environments
###################################################

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
      enabled   = local.is-production
      instances = data.aws_instances.windows_tagged_instances.ids
      # sns_topic = "arn:aws:sns:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:${local.application_data.accounts[local.environment].cloudwatch_sns_topic_name}"
      sns_topic = "arn:aws:sns:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:${local.application_data.accounts[local.environment].cloudwatch_sns_std_and_sms_topic_name}"
    }
    preproduction = {
      enabled   = local.is-preproduction
      instances = data.aws_instances.windows_tagged_instances_uat.ids
      sns_topic = "arn:aws:sns:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:${local.application_data.accounts[local.environment].cloudwatch_sns_topic_name}"
    }
    development = {
      enabled   = local.is-development
      instances = data.aws_instances.windows_tagged_instances_dev.ids
      sns_topic = "arn:aws:sns:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:${local.application_data.accounts[local.environment].cloudwatch_sns_topic_name}"
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
