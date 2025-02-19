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
    bods_primary = {
      bods-cms-process-count = {
        alarm_description   = "This alarm checks that the PID count for the BODS CMS does not drop below 1."
        namespace           = "CWAgent"
        metric_name         = "procstat_lookup pid_count"
        period              = 60
        evaluation_periods  = 1
        statistic           = "Average"
        comparison_operator = "LessThanThreshold"
        threshold           = 1
        treat_missing_data  = "breaching"
        dimensions = {
          exe        = "CMS"
          pid_finder = "native"
        }
      }
      bods-data-services-process-count = {
        alarm_description   = "This alarm checks that the PID count for Data Services does not drop below 1."
        namespace           = "CWAgent"
        metric_name         = "procstat_lookup pid_count"
        period              = 60
        evaluation_periods  = 1
        statistic           = "Average"
        comparison_operator = "LessThanThreshold"
        threshold           = 1
        treat_missing_data  = "breaching"
        dimensions = {
          exe        = "AL_JobService"
          pid_finder = "native"
        }
      }
    }
    bods_secondary = {
      bods-data-services-process-count = {
        alarm_description   = "This alarm checks that the PID count for Data Services does not drop below 1."
        namespace           = "CWAgent"
        metric_name         = "procstat_lookup pid_count"
        period              = 60
        evaluation_periods  = 1
        statistic           = "Average"
        comparison_operator = "LessThanThreshold"
        threshold           = 1
        treat_missing_data  = "breaching"
        dimensions = {
          exe        = "AL_JobService"
          pid_finder = "native"
        }
      }
    }
  }
}
