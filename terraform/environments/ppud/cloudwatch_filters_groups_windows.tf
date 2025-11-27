####################################################################
# CloudWatch Metric Filters and Log Groups for EC2 Instances Windows
####################################################################

###############################
# Windows Log Groups Production
###############################

resource "aws_cloudwatch_log_group" "IIS-Logs" {
  # checkov:skip=CKV_AWS_158: "CloudWatch log group is not public facing, does not contain any sensitive information and does not need encryption"
  count             = local.is-production == true ? 1 : 0
  name              = "IIS-Logs"
  retention_in_days = 365
}

resource "aws_cloudwatch_log_group" "System-Event-Logs" {
  # checkov:skip=CKV_AWS_158: "CloudWatch log group is not public facing, does not contain any sensitive information and does not need encryption"
  count             = local.is-production == true ? 1 : 0
  name              = "System-Event-Logs"
  retention_in_days = 365
}

resource "aws_cloudwatch_log_group" "Application-Event-Logs" {
  # checkov:skip=CKV_AWS_158: "CloudWatch log group is not public facing, does not contain any sensitive information and does not need encryption"
  count             = local.is-production == true ? 1 : 0
  name              = "Application-Event-Logs"
  retention_in_days = 365
}

resource "aws_cloudwatch_log_group" "Windows-Services-Logs" {
  # checkov:skip=CKV_AWS_158: "CloudWatch log group is not public facing, does not contain any sensitive information and does not need encryption"
  count             = local.is-production == true ? 1 : 0
  name              = "Windows-Services-Logs"
  retention_in_days = 365
}

resource "aws_cloudwatch_log_group" "Network-Connectivity-Logs" {
  # checkov:skip=CKV_AWS_158: "CloudWatch log group is not public facing, does not contain any sensitive information and does not need encryption"
  count             = local.is-production == true ? 1 : 0
  name              = "Network-Connectivity-Logs"
  retention_in_days = 365
}

resource "aws_cloudwatch_log_group" "SQL-Server-Logs" {
  # checkov:skip=CKV_AWS_158: "CloudWatch log group is not public facing, does not contain any sensitive information and does not need encryption"
  count             = local.is-production == true ? 1 : 0
  name              = "SQL-Server-Logs"
  retention_in_days = 365
}

resource "aws_cloudwatch_log_group" "Windows-Defender-Logs" {
  # checkov:skip=CKV_AWS_158: "CloudWatch log group is not public facing, does not contain any sensitive information and does not need encryption"
  count             = local.is-production == true ? 1 : 0
  name              = "Windows-Defender-Logs"
  retention_in_days = 365
}

resource "aws_cloudwatch_log_group" "Custom-Event-Logs" {
  # checkov:skip=CKV_AWS_158: "CloudWatch log group is not public facing, does not contain any sensitive information and does not need encryption"
  count             = local.is-production == true ? 1 : 0
  name              = "Custom-Event-Logs"
  retention_in_days = 365
}

##################################
# Windows Log Groups Preproduction
##################################

resource "aws_cloudwatch_log_group" "Windows-Defender-Logs-Preproduction" {
  # checkov:skip=CKV_AWS_158: "CloudWatch log group is not public facing, does not contain any sensitive information and does not need encryption"
  count             = local.is-preproduction == true ? 1 : 0
  name              = "Windows-Defender-Logs"
  retention_in_days = 365
}

################################
# Windows Log Groups Development
################################

resource "aws_cloudwatch_log_group" "Windows-Defender-Logs-Development" {
  # checkov:skip=CKV_AWS_158: "CloudWatch log group is not public facing, does not contain any sensitive information and does not need encryption"
  count             = local.is-development == true ? 1 : 0
  name              = "Windows-Defender-Logs"
  retention_in_days = 365
}

###################################
# Windows Metric Filters Production
###################################

# Windows Services Metric Filters

resource "aws_cloudwatch_log_metric_filter" "ServiceStatus-Running" {
  count          = local.is-production == true ? 1 : 0
  name           = "ServiceStatus-Running"
  log_group_name = aws_cloudwatch_log_group.Windows-Services-Logs[count.index].name
  pattern        = "[date, time, Instance, Service, status=Running]"
  metric_transformation {
    name      = "IsRunning"
    namespace = "ServiceStatus"
    value     = "1"
    dimensions = {
      Instance = "$Instance"
      Service  = "$Service"
    }
  }
}

resource "aws_cloudwatch_log_metric_filter" "ServiceStatus-NotRunning" {
  count          = local.is-production == true ? 1 : 0
  name           = "ServiceStatus-NotRunning"
  log_group_name = aws_cloudwatch_log_group.Windows-Services-Logs[count.index].name
  pattern        = "[date, time, Instance, Service, status!=Running]"
  metric_transformation {
    name      = "IsRunning"
    namespace = "ServiceStatus"
    value     = "0"
    dimensions = {
      Instance = "$Instance"
      Service  = "$Service"
    }
  }
}

# SMTP Port 25 Metric Filters

resource "aws_cloudwatch_log_metric_filter" "PortStatus-True" {
  count          = local.is-production == true ? 1 : 0
  name           = "PortStatus-True"
  log_group_name = aws_cloudwatch_log_group.Network-Connectivity-Logs[count.index].name
  pattern        = "[date, time, Instance, Port25, status!=False]"
  metric_transformation {
    name      = "PortStatus"
    namespace = "Port"
    value     = "1"
    dimensions = {
      Instance = "$Instance"
      Port     = "$Port25"
    }
  }
}

resource "aws_cloudwatch_log_metric_filter" "PortStatus-False" {
  count          = local.is-production == true ? 1 : 0
  name           = "PortStatus-False"
  log_group_name = aws_cloudwatch_log_group.Network-Connectivity-Logs[count.index].name
  pattern        = "[date, time, Instance, Port25, status=False]"
  metric_transformation {
    name      = "PortStatus"
    namespace = "Port"
    value     = "0"
    dimensions = {
      Instance = "$Instance"
      Port     = "$Port25"
    }
  }
}

# SQL Server Metric Filters

resource "aws_cloudwatch_log_metric_filter" "SQLBackupStatus-Successful" {
  count          = local.is-production == true ? 1 : 0
  name           = "SQLBackupStatus-Successful"
  log_group_name = aws_cloudwatch_log_group.SQL-Server-Logs[count.index].name
  pattern        = "[date, time, Instance, SQLBackup, status=Successful]"
  metric_transformation {
    name      = "SQLBackupStatus"
    namespace = "SQLBackup"
    value     = "1"
    dimensions = {
      Instance = "$Instance"
    }
  }
}

resource "aws_cloudwatch_log_metric_filter" "SQLBackupStatus-Failed" {
  count          = local.is-production == true ? 1 : 0
  name           = "SQLBackupStatus-Failed"
  log_group_name = aws_cloudwatch_log_group.SQL-Server-Logs[count.index].name
  pattern        = "[date, time, Instance, SQLBackup, status!=Successful]"
  metric_transformation {
    name      = "SQLBackupStatus"
    namespace = "SQLBackup"
    value     = "0"
    dimensions = {
      Instance = "$Instance"
    }
  }
}

# EmailSender Log Application Metric Filters

resource "aws_cloudwatch_log_metric_filter" "EmailSender-True" {
  count          = local.is-production == true ? 1 : 0
  name           = "EmailSender-True"
  log_group_name = aws_cloudwatch_log_group.Custom-Event-Logs[count.index].name
  pattern        = "[date, time, Instance, EmailSender, status!=False]"
  metric_transformation {
    name      = "EmailSenderStatus"
    namespace = "EmailSender"
    value     = "1"
    dimensions = {
      Instance    = "$Instance"
      EmailSender = "$EmailSender"
    }
  }
}

resource "aws_cloudwatch_log_metric_filter" "EmailSender-False" {
  count          = local.is-production == true ? 1 : 0
  name           = "EmailSender-False"
  log_group_name = aws_cloudwatch_log_group.Custom-Event-Logs[count.index].name
  pattern        = "[date, time, Instance, EmailSender, status=False]"
  metric_transformation {
    name      = "EmailSenderStatus"
    namespace = "EmailSender"
    value     = "0"
    dimensions = {
      Instance    = "$Instance"
      EmailSender = "$EmailSender"
    }
  }
}
/*
# Windows Defender Event Metric Filters

locals {
  malware_metrics_prod = local.is-production ? {
    MalwareScanStarted      = 1000
    MalwareScanFinished     = 1001
    MalwareScanStopped      = 1002
    MalwareScanFailed       = 1005
    MalwareBehaviorDetected = 1015
    MalwareStateDetected    = 1116
    MalwareSignatureFailed  = 2001
    MalwareEngineFailed     = 2003
    MalwareEngineOutofDate  = 2005
  } : {}
}

resource "aws_cloudwatch_log_metric_filter" "malware_metrics_production" {
  for_each       = local.is-production ? local.malware_metrics_prod : {}
  name           = each.key
  log_group_name = aws_cloudwatch_log_group.Windows-Defender-Logs[0].name
  pattern        = "[date, time, Instance, EventName, status=${each.value}]"

  metric_transformation {
    name      = each.key
    namespace = "WindowsDefender"
    value     = "1"
    dimensions = {
      Instance  = "$Instance"
      EventName = "$EventName"
    }
  }
}

######################################
# Windows Metric Filters Preproduction
######################################

# Windows Defender Event Metric Filters

locals {
  malware_metrics_preprod = local.is-preproduction ? {
    MalwareScanStarted      = 1000
    MalwareScanFinished     = 1001
    MalwareScanStopped      = 1002
    MalwareScanFailed       = 1005
    MalwareBehaviorDetected = 1015
    MalwareStateDetected    = 1116
    MalwareSignatureFailed  = 2001
    MalwareEngineFailed     = 2003
    MalwareEngineOutofDate  = 2005
  } : {}
}

resource "aws_cloudwatch_log_metric_filter" "malware_metrics_preproduction" {
  for_each       = local.is-preproduction ? local.malware_metrics_preprod : {}
  name           = each.key
  log_group_name = aws_cloudwatch_log_group.Windows-Defender-Logs-Preproduction[0].name
  pattern        = "[date, time, Instance, EventName, status=${each.value}]"

  metric_transformation {
    name      = each.key
    namespace = "WindowsDefender"
    value     = "1"
    dimensions = {
      Instance  = "$Instance"
      EventName = "$EventName"
    }
  }
}

####################################
# Windows Metric Filters Development
####################################

# Windows Defender Event Metric Filters

locals {
  malware_metrics_dev = local.is-development ? {
    MalwareScanStarted      = 1000
    MalwareScanFinished     = 1001
    MalwareScanStopped      = 1002
    MalwareScanFailed       = 1005
    MalwareBehaviorDetected = 1015
    MalwareStateDetected    = 1116
    MalwareSignatureFailed  = 2001
    MalwareEngineFailed     = 2003
    MalwareEngineOutofDate  = 2005
  } : {}
}

resource "aws_cloudwatch_log_metric_filter" "malware_metrics_development" {
  for_each       = local.is-development ? local.malware_metrics_dev : {}
  name           = each.key
  log_group_name = aws_cloudwatch_log_group.Windows-Defender-Logs-Development[0].name
  pattern        = "[date, time, Instance, EventName, status=${each.value}]"

  metric_transformation {
    name      = each.key
    namespace = "WindowsDefender"
    value     = "1"
    dimensions = {
      Instance  = "$Instance"
      EventName = "$EventName"
    }
  }
}
*/
#Windows Defender Event Metric Filters

locals {
  malware_metrics = {
    MalwareScanStarted      = 1000
    MalwareScanFinished     = 1001
    MalwareScanStopped      = 1002
    MalwareScanFailed       = 1005
    MalwareBehaviorDetected = 1015
    MalwareStateDetected    = 1116
    MalwareSignatureFailed  = 2001
    MalwareEngineFailed     = 2003
    MalwareEngineOutofDate  = 2005
  }

  malware_environments = {
    production    = { enabled = local.is-production, log_group = "Windows-Defender-Logs" }
    preproduction = { enabled = local.is-preproduction, log_group = "Windows-Defender-Logs-Preproduction" }
    development   = { enabled = local.is-development, log_group = "Windows-Defender-Logs-Development" }
  }

  malware_filter_matrix = flatten([
    for env_name, env_config in local.malware_environments : [
      for metric_name, event_id in local.malware_metrics : {
        key           = "${env_name}-${metric_name}"
        env_name      = env_name
        metric_name   = metric_name
        event_id      = event_id
        log_group_ref = env_config.log_group
        enabled       = env_config.enabled
      } if env_config.enabled
    ]
  ])
}

resource "aws_cloudwatch_log_metric_filter" "malware_metrics" {
  for_each = {
    for item in local.malware_filter_matrix : item.key => item
  }

  name = each.value.metric_name
  log_group_name = (
    each.value.env_name == "production" ? aws_cloudwatch_log_group.Windows-Defender-Logs[0].name :
    each.value.env_name == "preproduction" ? aws_cloudwatch_log_group.Windows-Defender-Logs-Preproduction[0].name :
    aws_cloudwatch_log_group.Windows-Defender-Logs-Development[0].name
  )
  pattern = "[date, time, Instance, EventName, status=${each.value.event_id}]"

  metric_transformation {
    name      = each.value.metric_name
    namespace = "WindowsDefender"
    value     = "1"
    dimensions = {
      Instance  = "$Instance"
      EventName = "$EventName"
    }
  }
}
