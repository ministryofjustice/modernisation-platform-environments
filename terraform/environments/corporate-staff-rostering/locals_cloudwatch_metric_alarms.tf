locals {

  cloudwatch_metric_alarms = {
    app = merge(
      module.baseline_presets.cloudwatch_metric_alarms_by_sns_topic["csr_pagerduty"].ec2,
      module.baseline_presets.cloudwatch_metric_alarms_by_sns_topic["csr_pagerduty"].ec2_cwagent_windows,
      module.baseline_presets.cloudwatch_metric_alarms_by_sns_topic["csr_pagerduty"].ec2_instance_or_cwagent_stopped_windows,
      local.cloudwatch_app_log_metric_alarms.app, {
        high-memory-usage = merge(module.baseline_presets.cloudwatch_metric_alarms_by_sns_topic["csr_pagerduty"].ec2_cwagent_windows["high-memory-usage"], {
          threshold           = "75"
          period              = "60" # seconds
          evaluation_periods  = "20"
          datapoints_to_alarm = "20"
          alarm_description   = "Triggers if the average memory utilization is 75% or above for 20 minutes. Set below the default of 95% to allow enough time to establish an RDP session to fix the issue."
        })
      }
    )

    db = merge(
      module.baseline_presets.cloudwatch_metric_alarms_by_sns_topic["csr_pagerduty"].ec2,
      module.baseline_presets.cloudwatch_metric_alarms_by_sns_topic["csr_pagerduty"].ec2_cwagent_linux,
      module.baseline_presets.cloudwatch_metric_alarms_by_sns_topic["csr_pagerduty"].ec2_instance_or_cwagent_stopped_linux,
      local.environment == "production" ? {} : {
        cpu-utilization-high = merge(module.baseline_presets.cloudwatch_metric_alarms_by_sns_topic["csr_pagerduty"].ec2["cpu-utilization-high"], {
          evaluation_periods  = "480"
          datapoints_to_alarm = "480"
          threshold           = "95"
          alarm_description   = "Triggers if the average cpu remains at 95% utilization or above for 8 hours to allow for DB refreshes. See https://dsdmoj.atlassian.net/wiki/spaces/DSTT/pages/4326064583"
        })
        cpu-iowait-high = merge(module.baseline_presets.cloudwatch_metric_alarms_by_sns_topic["csr_pagerduty"].ec2_cwagent_linux["cpu-iowait-high"], {
          evaluation_periods  = "480"
          datapoints_to_alarm = "480"
          threshold           = "40"
          alarm_description   = "Triggers if the amount of CPU time spent waiting for I/O to complete is continually high for 8 hours allowing for DB refreshes.  See https://dsdmoj.atlassian.net/wiki/spaces/DSTT/pages/4325900634"
        })
      }
    )

    db_backup = merge(
      module.baseline_presets.cloudwatch_metric_alarms_by_sns_topic["csr_pagerduty"].ec2_instance_cwagent_collectd_oracle_db_backup,
    )

    web = merge(
      module.baseline_presets.cloudwatch_metric_alarms_by_sns_topic["csr_pagerduty"].ec2,
      module.baseline_presets.cloudwatch_metric_alarms_by_sns_topic["csr_pagerduty"].ec2_cwagent_windows,
      module.baseline_presets.cloudwatch_metric_alarms_by_sns_topic["csr_pagerduty"].ec2_instance_or_cwagent_stopped_windows,
      local.cloudwatch_app_log_metric_alarms.web,
    )
  }
}
