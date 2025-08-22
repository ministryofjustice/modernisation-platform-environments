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

# Windows Defender Event Metric Filters

resource "aws_cloudwatch_log_metric_filter" "MalwareScanStarted" {
  count          = local.is-production == true ? 1 : 0
  name           = "MalwareScanStarted"
  log_group_name = aws_cloudwatch_log_group.Windows-Defender-Logs[count.index].name
  pattern        = "[date, time, Instance, MalwareScanStarted, status=1000]"
  metric_transformation {
    name      = "MalwareScanStarted"
    namespace = "WindowsDefender"
    value     = "1"
    dimensions = {
      Instance           = "$Instance"
      MalwareScanStarted = "$MalwareScanStarted"
    }
  }
}

resource "aws_cloudwatch_log_metric_filter" "MalwareScanFinished" {
  count          = local.is-production == true ? 1 : 0
  name           = "MalwareScanFinished"
  log_group_name = aws_cloudwatch_log_group.Windows-Defender-Logs[count.index].name
  pattern        = "[date, time, Instance, MalwareScanFinished, status=1001]"
  metric_transformation {
    name      = "MalwareScanFinished"
    namespace = "WindowsDefender"
    value     = "1"
    dimensions = {
      Instance            = "$Instance"
      MalwareScanFinished = "$MalwareScanFinished"
    }
  }
}

resource "aws_cloudwatch_log_metric_filter" "MalwareScanStopped" {
  count          = local.is-production == true ? 1 : 0
  name           = "MalwareScanStopped"
  log_group_name = aws_cloudwatch_log_group.Windows-Defender-Logs[count.index].name
  pattern        = "[date, time, Instance, MalwareScanStopped, status=1002]"
  metric_transformation {
    name      = "MalwareScanStopped"
    namespace = "WindowsDefender"
    value     = "1"
    dimensions = {
      Instance           = "$Instance"
      MalwareScanStopped = "$MalwareScanStopped"
    }
  }
}

resource "aws_cloudwatch_log_metric_filter" "MalwareScanFailed" {
  count          = local.is-production == true ? 1 : 0
  name           = "MalwareScanFailed"
  log_group_name = aws_cloudwatch_log_group.Windows-Defender-Logs[count.index].name
  pattern        = "[date, time, Instance, MalwareScanFailed, status=1005]"
  metric_transformation {
    name      = "MalwareScanFailed"
    namespace = "WindowsDefender"
    value     = "1"
    dimensions = {
      Instance          = "$Instance"
      MalwareScanFailed = "$MalwareScanFailed"
    }
  }
}

resource "aws_cloudwatch_log_metric_filter" "MalwareBehaviorDetected" {
  count          = local.is-production == true ? 1 : 0
  name           = "MalwareBehaviorDetected"
  log_group_name = aws_cloudwatch_log_group.Windows-Defender-Logs[count.index].name
  pattern        = "[date, time, Instance, MalwareBehaviorDetected, status=1015]"
  metric_transformation {
    name      = "MalwareBehaviorDetected"
    namespace = "WindowsDefender"
    value     = "1"
    dimensions = {
      Instance                = "$Instance"
      MalwareBehaviorDetected = "$MalwareBehaviorDetected"
    }
  }
}

resource "aws_cloudwatch_log_metric_filter" "MalwareStateDetected" {
  count          = local.is-production == true ? 1 : 0
  name           = "MalwareStateDetected"
  log_group_name = aws_cloudwatch_log_group.Windows-Defender-Logs[count.index].name
  pattern        = "[date, time, Instance, MalwareStateDetected, status=1116]"
  metric_transformation {
    name      = "MalwareStateDetected"
    namespace = "WindowsDefender"
    value     = "1"
    dimensions = {
      Instance             = "$Instance"
      MalwareStateDetected = "$MalwareStateDetected"
    }
  }
}

resource "aws_cloudwatch_log_metric_filter" "MalwareSignatureFailed" {
  count          = local.is-production == true ? 1 : 0
  name           = "MalwareSignatureFailed"
  log_group_name = aws_cloudwatch_log_group.Windows-Defender-Logs[count.index].name
  pattern        = "[date, time, Instance, MalwareSignatureFailed, status=2001]"
  metric_transformation {
    name      = "MalwareSignatureFailed"
    namespace = "WindowsDefender"
    value     = "1"
    dimensions = {
      Instance               = "$Instance"
      MalwareSignatureFailed = "$MalwareSignatureFailed"
    }
  }
}

resource "aws_cloudwatch_log_metric_filter" "MalwareEngineFailed" {
  count          = local.is-production == true ? 1 : 0
  name           = "MalwareEngineFailed"
  log_group_name = aws_cloudwatch_log_group.Windows-Defender-Logs[count.index].name
  pattern        = "[date, time, Instance, MalwareEngineFailed, status=2003]"
  metric_transformation {
    name      = "MalwareEngineFailed"
    namespace = "WindowsDefender"
    value     = "1"
    dimensions = {
      Instance            = "$Instance"
      MalwareEngineFailed = "$MalwareEngineFailed"
    }
  }
}

resource "aws_cloudwatch_log_metric_filter" "MalwareEngineOutofDate" {
  count          = local.is-production == true ? 1 : 0
  name           = "MalwareEngineOutofDate"
  log_group_name = aws_cloudwatch_log_group.Windows-Defender-Logs[count.index].name
  pattern        = "[date, time, Instance, MalwareEngineOutofDate, status=2005]"
  metric_transformation {
    name      = "MalwareEngineOutofDate"
    namespace = "WindowsDefender"
    value     = "1"
    dimensions = {
      Instance               = "$Instance"
      MalwareEngineOutofDate = "$MalwareEngineOutofDate"
    }
  }
}

######################################
# Windows Metric Filters Preproduction
######################################

# Windows Defender Event Metric Filters

resource "aws_cloudwatch_log_metric_filter" "MalwareScanStarted-Preproduction" {
  count          = local.is-preproduction == true ? 1 : 0
  name           = "MalwareScanStarted"
  log_group_name = aws_cloudwatch_log_group.Windows-Defender-Logs-Preproduction[count.index].name
  pattern        = "[date, time, Instance, MalwareScanStarted, status=1000]"
  metric_transformation {
    name      = "MalwareScanStarted"
    namespace = "WindowsDefender"
    value     = "1"
    dimensions = {
      Instance           = "$Instance"
      MalwareScanStarted = "$MalwareScanStarted"
    }
  }
}

resource "aws_cloudwatch_log_metric_filter" "MalwareScanFinished-Preproduction" {
  count          = local.is-preproduction == true ? 1 : 0
  name           = "MalwareScanFinished"
  log_group_name = aws_cloudwatch_log_group.Windows-Defender-Logs-Preproduction[count.index].name
  pattern        = "[date, time, Instance, MalwareScanFinished, status=1001]"
  metric_transformation {
    name      = "MalwareScanFinished"
    namespace = "WindowsDefender"
    value     = "1"
    dimensions = {
      Instance            = "$Instance"
      MalwareScanFinished = "$MalwareScanFinished"
    }
  }
}

resource "aws_cloudwatch_log_metric_filter" "MalwareScanStopped-Preproduction" {
  count          = local.is-preproduction == true ? 1 : 0
  name           = "MalwareScanStopped"
  log_group_name = aws_cloudwatch_log_group.Windows-Defender-Logs-Preproduction[count.index].name
  pattern        = "[date, time, Instance, MalwareScanStopped, status=1002]"
  metric_transformation {
    name      = "MalwareScanStopped"
    namespace = "WindowsDefender"
    value     = "1"
    dimensions = {
      Instance           = "$Instance"
      MalwareScanStopped = "$MalwareScanStopped"
    }
  }
}

resource "aws_cloudwatch_log_metric_filter" "MalwareScanFailed-Preproduction" {
  count          = local.is-preproduction == true ? 1 : 0
  name           = "MalwareScanFailed"
  log_group_name = aws_cloudwatch_log_group.Windows-Defender-Logs-Preproduction[count.index].name
  pattern        = "[date, time, Instance, MalwareScanFailed, status=1005]"
  metric_transformation {
    name      = "MalwareScanFailed"
    namespace = "WindowsDefender"
    value     = "1"
    dimensions = {
      Instance          = "$Instance"
      MalwareScanFailed = "$MalwareScanFailed"
    }
  }
}

resource "aws_cloudwatch_log_metric_filter" "MalwareBehaviorDetected-Preproduction" {
  count          = local.is-preproduction == true ? 1 : 0
  name           = "MalwareBehaviorDetected"
  log_group_name = aws_cloudwatch_log_group.Windows-Defender-Logs-Preproduction[count.index].name
  pattern        = "[date, time, Instance, MalwareBehaviorDetected, status=1015]"
  metric_transformation {
    name      = "MalwareBehaviorDetected"
    namespace = "WindowsDefender"
    value     = "1"
    dimensions = {
      Instance                = "$Instance"
      MalwareBehaviorDetected = "$MalwareBehaviorDetected"
    }
  }
}

resource "aws_cloudwatch_log_metric_filter" "MalwareStateDetected-Preproduction" {
  count          = local.is-preproduction == true ? 1 : 0
  name           = "MalwareStateDetected"
  log_group_name = aws_cloudwatch_log_group.Windows-Defender-Logs-Preproduction[count.index].name
  pattern        = "[date, time, Instance, MalwareStateDetected, status=1116]"
  metric_transformation {
    name      = "MalwareStateDetected"
    namespace = "WindowsDefender"
    value     = "1"
    dimensions = {
      Instance             = "$Instance"
      MalwareStateDetected = "$MalwareStateDetected"
    }
  }
}

resource "aws_cloudwatch_log_metric_filter" "MalwareSignatureFailed-Preproduction" {
  count          = local.is-preproduction == true ? 1 : 0
  name           = "MalwareSignatureFailed"
  log_group_name = aws_cloudwatch_log_group.Windows-Defender-Logs-Preproduction[count.index].name
  pattern        = "[date, time, Instance, MalwareSignatureFailed, status=2001]"
  metric_transformation {
    name      = "MalwareSignatureFailed"
    namespace = "WindowsDefender"
    value     = "1"
    dimensions = {
      Instance               = "$Instance"
      MalwareSignatureFailed = "$MalwareSignatureFailed"
    }
  }
}

resource "aws_cloudwatch_log_metric_filter" "MalwareEngineFailed-Preproduction" {
  count          = local.is-preproduction == true ? 1 : 0
  name           = "MalwareEngineFailed"
  log_group_name = aws_cloudwatch_log_group.Windows-Defender-Logs-Preproduction[count.index].name
  pattern        = "[date, time, Instance, MalwareEngineFailed, status=2003]"
  metric_transformation {
    name      = "MalwareEngineFailed"
    namespace = "WindowsDefender"
    value     = "1"
    dimensions = {
      Instance            = "$Instance"
      MalwareEngineFailed = "$MalwareEngineFailed"
    }
  }
}

resource "aws_cloudwatch_log_metric_filter" "MalwareEngineOutofDate-Preproduction" {
  count          = local.is-preproduction == true ? 1 : 0
  name           = "MalwareEngineOutofDate"
  log_group_name = aws_cloudwatch_log_group.Windows-Defender-Logs-Preproduction[count.index].name
  pattern        = "[date, time, Instance, MalwareEngineOutofDate, status=2005]"
  metric_transformation {
    name      = "MalwareEngineOutofDate"
    namespace = "WindowsDefender"
    value     = "1"
    dimensions = {
      Instance               = "$Instance"
      MalwareEngineOutofDate = "$MalwareEngineOutofDate"
    }
  }
}

####################################
# Windows Metric Filters Development
####################################

# Windows Defender Event Metric Filters

resource "aws_cloudwatch_log_metric_filter" "MalwareScanStarted-Development" {
  count          = local.is-development == true ? 1 : 0
  name           = "MalwareScanStarted"
  log_group_name = aws_cloudwatch_log_group.Windows-Defender-Logs-Development[count.index].name
  pattern        = "[date, time, Instance, MalwareScanStarted, status=1000]"
  metric_transformation {
    name      = "MalwareScanStarted"
    namespace = "WindowsDefender"
    value     = "1"
    dimensions = {
      Instance           = "$Instance"
      MalwareScanStarted = "$MalwareScanStarted"
    }
  }
}

resource "aws_cloudwatch_log_metric_filter" "MalwareScanFinished-Development" {
  count          = local.is-development == true ? 1 : 0
  name           = "MalwareScanFinished"
  log_group_name = aws_cloudwatch_log_group.Windows-Defender-Logs-Development[count.index].name
  pattern        = "[date, time, Instance, MalwareScanFinished, status=1001]"
  metric_transformation {
    name      = "MalwareScanFinished"
    namespace = "WindowsDefender"
    value     = "1"
    dimensions = {
      Instance            = "$Instance"
      MalwareScanFinished = "$MalwareScanFinished"
    }
  }
}

resource "aws_cloudwatch_log_metric_filter" "MalwareScanStopped-Development" {
  count          = local.is-development == true ? 1 : 0
  name           = "MalwareScanStopped"
  log_group_name = aws_cloudwatch_log_group.Windows-Defender-Logs-Development[count.index].name
  pattern        = "[date, time, Instance, MalwareScanStopped, status=1002]"
  metric_transformation {
    name      = "MalwareScanStopped"
    namespace = "WindowsDefender"
    value     = "1"
    dimensions = {
      Instance           = "$Instance"
      MalwareScanStopped = "$MalwareScanStopped"
    }
  }
}

resource "aws_cloudwatch_log_metric_filter" "MalwareScanFailed-Development" {
  count          = local.is-development == true ? 1 : 0
  name           = "MalwareScanFailed"
  log_group_name = aws_cloudwatch_log_group.Windows-Defender-Logs-Development[count.index].name
  pattern        = "[date, time, Instance, MalwareScanFailed, status=1005]"
  metric_transformation {
    name      = "MalwareScanFailed"
    namespace = "WindowsDefender"
    value     = "1"
    dimensions = {
      Instance          = "$Instance"
      MalwareScanFailed = "$MalwareScanFailed"
    }
  }
}

resource "aws_cloudwatch_log_metric_filter" "MalwareBehaviorDetected-Development" {
  count          = local.is-development == true ? 1 : 0
  name           = "MalwareBehaviorDetected"
  log_group_name = aws_cloudwatch_log_group.Windows-Defender-Logs-Development[count.index].name
  pattern        = "[date, time, Instance, MalwareBehaviorDetected, status=1015]"
  metric_transformation {
    name      = "MalwareBehaviorDetected"
    namespace = "WindowsDefender"
    value     = "1"
    dimensions = {
      Instance                = "$Instance"
      MalwareBehaviorDetected = "$MalwareBehaviorDetected"
    }
  }
}

resource "aws_cloudwatch_log_metric_filter" "MalwareStateDetected-Development" {
  count          = local.is-development == true ? 1 : 0
  name           = "MalwareStateDetected"
  log_group_name = aws_cloudwatch_log_group.Windows-Defender-Logs-Development[count.index].name
  pattern        = "[date, time, Instance, MalwareStateDetected, status=1116]"
  metric_transformation {
    name      = "MalwareStateDetected"
    namespace = "WindowsDefender"
    value     = "1"
    dimensions = {
      Instance             = "$Instance"
      MalwareStateDetected = "$MalwareStateDetected"
    }
  }
}

resource "aws_cloudwatch_log_metric_filter" "MalwareSignatureFailed-Development" {
  count          = local.is-development == true ? 1 : 0
  name           = "MalwareSignatureFailed"
  log_group_name = aws_cloudwatch_log_group.Windows-Defender-Logs-Development[count.index].name
  pattern        = "[date, time, Instance, MalwareSignatureFailed, status=2001]"
  metric_transformation {
    name      = "MalwareSignatureFailed"
    namespace = "WindowsDefender"
    value     = "1"
    dimensions = {
      Instance               = "$Instance"
      MalwareSignatureFailed = "$MalwareSignatureFailed"
    }
  }
}

resource "aws_cloudwatch_log_metric_filter" "MalwareEngineFailed-Development" {
  count          = local.is-development == true ? 1 : 0
  name           = "MalwareEngineFailed"
  log_group_name = aws_cloudwatch_log_group.Windows-Defender-Logs-Development[count.index].name
  pattern        = "[date, time, Instance, MalwareEngineFailed, status=2003]"
  metric_transformation {
    name      = "MalwareEngineFailed"
    namespace = "WindowsDefender"
    value     = "1"
    dimensions = {
      Instance            = "$Instance"
      MalwareEngineFailed = "$MalwareEngineFailed"
    }
  }
}

resource "aws_cloudwatch_log_metric_filter" "MalwareEngineOutofDate-Development" {
  count          = local.is-development == true ? 1 : 0
  name           = "MalwareEngineOutofDate"
  log_group_name = aws_cloudwatch_log_group.Windows-Defender-Logs-Development[count.index].name
  pattern        = "[date, time, Instance, MalwareEngineOutofDate, status=2005]"
  metric_transformation {
    name      = "MalwareEngineOutofDate"
    namespace = "WindowsDefender"
    value     = "1"
    dimensions = {
      Instance               = "$Instance"
      MalwareEngineOutofDate = "$MalwareEngineOutofDate"
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
