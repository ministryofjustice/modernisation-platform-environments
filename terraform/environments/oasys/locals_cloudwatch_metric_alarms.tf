locals {

  cloudwatch_metric_alarms_additional = {
    ec2 = {
      low-inodes = {
        comparison_operator = "GreaterThanOrEqualToThreshold"
        evaluation_periods  = "15"
        datapoints_to_alarm = "15"
        metric_name         = "collectd_inode_used_percent_value"
        namespace           = "CWAgent"
        period              = "60"
        statistic           = "Maximum"
        threshold           = "85"
        alarm_description   = "Triggers if free inodes falls below the threshold for an hour"
        alarm_actions       = ["pagerduty"]
        ok_actions          = ["pagerduty"]
      }
    }
  }

  cloudwatch_metric_alarms = {

    db = merge(
      module.baseline_presets.cloudwatch_metric_alarms.ec2,
      module.baseline_presets.cloudwatch_metric_alarms.ec2_cwagent_linux,
      module.baseline_presets.cloudwatch_metric_alarms.ec2_instance_or_cwagent_stopped_linux,
      module.baseline_presets.cloudwatch_metric_alarms.ec2_instance_cwagent_collectd_service_status_os,
      module.baseline_presets.cloudwatch_metric_alarms.ec2_instance_cwagent_collectd_service_status_app,
      local.cloudwatch_metric_alarms_additional.ec2,
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
      },
      # DBAs have slack integration via OEM for this so don't include pagerduty integration
      module.baseline_presets.cloudwatch_metric_alarms.ec2_instance_cwagent_collectd_oracle_db_connected,
    )

    db_backup = merge(
      module.baseline_presets.cloudwatch_metric_alarms.ec2_instance_cwagent_collectd_oracle_db_backup,
    )

    bip = merge(
      module.baseline_presets.cloudwatch_metric_alarms.ec2,
      module.baseline_presets.cloudwatch_metric_alarms.ec2_cwagent_linux,
      module.baseline_presets.cloudwatch_metric_alarms.ec2_instance_or_cwagent_stopped_linux,
      module.baseline_presets.cloudwatch_metric_alarms.ec2_instance_cwagent_collectd_service_status_os,
      module.baseline_presets.cloudwatch_metric_alarms.ec2_instance_cwagent_collectd_service_status_app,
      local.cloudwatch_metric_alarms_additional.ec2,
    )

    web = merge(
      module.baseline_presets.cloudwatch_metric_alarms.ec2,
      module.baseline_presets.cloudwatch_metric_alarms.ec2_cwagent_linux,
      module.baseline_presets.cloudwatch_metric_alarms.ec2_instance_cwagent_collectd_service_status_os,
      module.baseline_presets.cloudwatch_metric_alarms.ec2_instance_cwagent_collectd_service_status_app,
      local.cloudwatch_metric_alarms_additional.ec2,
    )
  }
}
