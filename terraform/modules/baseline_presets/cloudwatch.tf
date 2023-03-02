locals {

  cloudwatch_log_groups = {
    session-manager-logs = {
      retention_in_days = 90
    }
    cwagent-var-log-messages = {
      retention_in_days = 30
    }
    cwagent-var-log-secure = {
      retention_in_days = 90
    }
    cwagent-windows-system = {
      retention_in_days = 30
    }
  }
}
