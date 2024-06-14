locals {

  cloudwatch_log_groups = {
    session-manager-logs = {
      retention_in_days = var.options.cloudwatch_log_groups_retention_in_days
    }
    cwagent-var-log-messages = {
      retention_in_days = var.options.cloudwatch_log_groups_retention_in_days
    }
    cwagent-var-log-secure = {
      retention_in_days = var.options.cloudwatch_log_groups_retention_in_days
    }
    cwagent-windows-system = {
      retention_in_days = var.options.cloudwatch_log_groups_retention_in_days
    }
  }
}
