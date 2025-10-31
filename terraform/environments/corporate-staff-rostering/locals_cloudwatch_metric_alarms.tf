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
    app = merge(
      module.baseline_presets.cloudwatch_metric_alarms.ec2,
      module.baseline_presets.cloudwatch_metric_alarms.ec2_cwagent_windows,
      module.baseline_presets.cloudwatch_metric_alarms.ec2_instance_or_cwagent_stopped_windows,
      {
        high-memory-usage = merge(module.baseline_presets.cloudwatch_metric_alarms.ec2_cwagent_windows["high-memory-usage"], {
          threshold           = "75"
          period              = "60" # seconds
          evaluation_periods  = "20"
          datapoints_to_alarm = "20"
          alarm_description   = "Triggers if the average memory utilization is 75% or above for 20 minutes. Set below the default of 95% to allow enough time to establish an RDP session to fix the issue."
        })
      }
    )

    db = merge(
      module.baseline_presets.cloudwatch_metric_alarms.ec2,
      module.baseline_presets.cloudwatch_metric_alarms.ec2_cwagent_linux,
      module.baseline_presets.cloudwatch_metric_alarms.ec2_instance_or_cwagent_stopped_linux,
      local.environment == "production" ? {} : {
        cpu-utilization-high = merge(module.baseline_presets.cloudwatch_metric_alarms.ec2["cpu-utilization-high"], {
          evaluation_periods  = "480"
          datapoints_to_alarm = "480"
          threshold           = "95"
          alarm_description   = "Triggers if the average cpu remains at 95% utilization or above for 8 hours to allow for DB refreshes. See https://dsdmoj.atlassian.net/wiki/spaces/DSTT/pages/4326064583"
        })
        cpu-iowait-high = merge(module.baseline_presets.cloudwatch_metric_alarms.ec2_cwagent_linux["cpu-iowait-high"], {
          evaluation_periods  = "480"
          datapoints_to_alarm = "480"
          threshold           = "40"
          alarm_description   = "Triggers if the amount of CPU time spent waiting for I/O to complete is continually high for 8 hours allowing for DB refreshes.  See https://dsdmoj.atlassian.net/wiki/spaces/DSTT/pages/4325900634"
        })
      }
    )

    db_backup = merge(
      module.baseline_presets.cloudwatch_metric_alarms.ec2_instance_cwagent_collectd_oracle_db_backup,
    )

    web = merge(
      module.baseline_presets.cloudwatch_metric_alarms.ec2,
      module.baseline_presets.cloudwatch_metric_alarms.ec2_cwagent_windows,
      module.baseline_presets.cloudwatch_metric_alarms.ec2_instance_or_cwagent_stopped_windows,
    )
  }
}
