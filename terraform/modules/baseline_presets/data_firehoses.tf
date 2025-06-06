locals {

  data_firehoses_filter = flatten([
    var.options.enable_xsiam_cloudwatch_integration && var.options.enable_ec2_session_manager_cloudwatch_logs ? ["session-manager-logs"] : [],
    var.options.enable_xsiam_cloudwatch_integration && var.options.enable_ec2_cloud_watch_agent ? ["linux-syslog", "windows-event-logs"] : []
  ])

  data_firehoses = {
    linux-syslog = {
      cloudwatch_log_group_names = [
        "cwagent-var-log-messages",
        "cwagent-var-log-secure",
      ]
      destination_http_secret_name                 = "/xsiam/http_endpoint_token_linux_syslog"
      destination_http_endpoint_ssm_parameter_name = "/xsiam/http_endpoint_url"
    }
    windows-event-logs = {
      cloudwatch_log_group_names = [
        "cwagent-windows-system",
        "cwagent-windows-application",
        "cwagent-windows-security",
      ]
      destination_http_secret_name                 = "/xsiam/http_endpoint_token_windows_event_logs"
      destination_http_endpoint_ssm_parameter_name = "/xsiam/http_endpoint_url"
    }
    session-manager-logs = {
      cloudwatch_log_group_names = [
        "session-manager-logs",
      ]
      destination_http_secret_name                 = "/xsiam/http_endpoint_token_session_manager_logs"
      destination_http_endpoint_ssm_parameter_name = "/xsiam/http_endpoint_url"
    }
  }
}
