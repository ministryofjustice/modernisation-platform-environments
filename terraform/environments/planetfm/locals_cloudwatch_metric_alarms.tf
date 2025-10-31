locals {
  cloudwatch_metric_alarms = {
    windows = {
      cwagent-process-count = {
        alarm_description   = "The CloudWatch agent runs 2 processes. If the PID count drops below 2, the agent is not functioning as expected."
        namespace           = "CWAgent"
        metric_name         = "procstat_lookup pid_count"
        period              = 60
        evaluation_periods  = 1
        statistic           = "Average"
        comparison_operator = "LessThanThreshold"
        threshold           = 2 # CloudWatch agent runs 2 processes
        treat_missing_data  = "breaching"
        dimensions = {
          exe        = "amazon-cloudwatch-agent"
          pid_finder = "native"
        }
      }
      ssm-agent-process-count = {
        alarm_description   = "The SSM agent runs 2 processes. If the PID count drops below 2, the agent is not functioning as expected."
        namespace           = "CWAgent"
        metric_name         = "procstat_lookup pid_count"
        period              = 60
        evaluation_periods  = 1
        statistic           = "Average"
        comparison_operator = "LessThanThreshold"
        threshold           = 2 # SSM agent runs 2 processes
        treat_missing_data  = "breaching"
        dimensions = {
          exe        = "ssm-agent"
          pid_finder = "native"
        }
      }
    }
  }
}
