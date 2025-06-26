locals {

  cloudwatch_metric_alarms = {
    db = merge(
      module.baseline_presets.cloudwatch_metric_alarms.ec2,
      module.baseline_presets.cloudwatch_metric_alarms.ec2_cwagent_linux,
      module.baseline_presets.cloudwatch_metric_alarms.ec2_instance_or_cwagent_stopped_linux,
      module.baseline_presets.cloudwatch_metric_alarms.ec2_instance_cwagent_collectd_service_status_os,
      module.baseline_presets.cloudwatch_metric_alarms.ec2_instance_cwagent_collectd_service_status_app,
      local.environment == "production" ? {
        cpu-utilization-high = merge(module.baseline_presets.cloudwatch_metric_alarms.ec2["cpu-utilization-high"], {
          evaluation_periods  = "15"
          datapoints_to_alarm = "15"
          threshold           = "95"
          alarm_description   = "Triggers if the average cpu remains at 95% utilization or above for 15 minutes. See https://dsdmoj.atlassian.net/wiki/spaces/DSTT/pages/4326064583"
        })
        cpu-iowait-high = merge(module.baseline_presets.cloudwatch_metric_alarms.ec2_cwagent_linux["cpu-iowait-high"], {
          evaluation_periods  = "15"
          datapoints_to_alarm = "15"
          threshold           = "50"
          alarm_description   = "Triggers if the amount of CPU time spent waiting for I/O to complete is continually high for 15 minutes. See https://dsdmoj.atlassian.net/wiki/spaces/DSTT/pages/4325900634"
        })
        } : {
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
    )
    db_connectivity_test = merge(
      module.baseline_presets.cloudwatch_metric_alarms.ec2_instance_cwagent_collectd_connectivity_test,
    )
    db_connected = merge(
      # DBAs have slack integration via OEM for this so don't include pagerduty integration
      module.baseline_presets.cloudwatch_metric_alarms.ec2_instance_cwagent_collectd_oracle_db_connected,
    )
    db_backup = merge(
      module.baseline_presets.cloudwatch_metric_alarms.ec2_instance_cwagent_collectd_oracle_db_backup,
    )
    db_nomis_batch = merge(
      module.baseline_presets.cloudwatch_metric_alarms.ec2_instance_cwagent_collectd_textfile_monitoring
    )
    db_misload = merge(
      module.baseline_presets.cloudwatch_metric_alarms.ec2_instance_cwagent_collectd_textfile_monitoring, {
        misload-long-running = {
          comparison_operator = "GreaterThanOrEqualToThreshold"
          evaluation_periods  = "1"
          datapoints_to_alarm = "1"
          namespace           = "CWAgent"
          metric_name         = "collectd_textfile_monitoring_seconds"
          period              = "300"
          statistic           = "Maximum"
          threshold           = "14400"
          treat_missing_data  = "notBreaching"
          alarm_description   = "Triggers if misload process is taking longer than 4 hours, see https://dsdmoj.atlassian.net/wiki/spaces/DSTT/pages/4615798942"
          alarm_actions       = ["pagerduty"]
          dimensions = {
            type          = "duration"
            type_instance = "misload_running"
          }
        }
      }
    )

    web = merge(
      module.baseline_presets.cloudwatch_metric_alarms.ec2,
      module.baseline_presets.cloudwatch_metric_alarms.ec2_cwagent_linux,
      module.baseline_presets.cloudwatch_metric_alarms.ec2_instance_cwagent_collectd_service_status_os,
      module.baseline_presets.cloudwatch_metric_alarms.ec2_instance_cwagent_collectd_service_status_app,
    )

    xtag = merge(
      module.baseline_presets.cloudwatch_metric_alarms.ec2,
      module.baseline_presets.cloudwatch_metric_alarms.ec2_cwagent_linux,
      module.baseline_presets.cloudwatch_metric_alarms.ec2_instance_or_cwagent_stopped_linux,
      module.baseline_presets.cloudwatch_metric_alarms.ec2_instance_cwagent_collectd_service_status_os,
      module.baseline_presets.cloudwatch_metric_alarms.ec2_instance_cwagent_collectd_service_status_app,
    )

    # Does not contain ec2_instance_or_cwagent_stopped_linux block as these machines are off overnight
    # This avoids triggering an alarm for the DBS's
    xtag_t1_t2 = merge(
      module.baseline_presets.cloudwatch_metric_alarms.ec2,
      module.baseline_presets.cloudwatch_metric_alarms.ec2_cwagent_linux,
      module.baseline_presets.cloudwatch_metric_alarms.ec2_instance_cwagent_collectd_service_status_os,
      module.baseline_presets.cloudwatch_metric_alarms.ec2_instance_cwagent_collectd_service_status_app,
    )
  }
}
