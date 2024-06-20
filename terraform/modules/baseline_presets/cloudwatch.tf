locals {

  cloudwatch_log_groups_filter = flatten([
    var.options.enable_ec2_session_manager_cloudwatch_logs ? ["session-manager-logs"] : [],
    var.options.enable_ec2_cloud_watch_agent ? ["cwagent-var-log-messages"] : [],
    var.options.enable_ec2_cloud_watch_agent ? ["cwagent-var-log-secure"] : [],
    var.options.enable_ec2_cloud_watch_agent ? ["cwagent-windows-system"] : [],
  ])

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
