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
    db_nomis_batch = {
      nomis-batch-error = {
        comparison_operator = "GreaterThanOrEqualToThreshold"
        evaluation_periods  = "3"
        datapoints_to_alarm = "3"
        namespace           = "CWAgent"
        metric_name         = "collectd_textfile_monitoring_value"
        period              = "60"
        statistic           = "Maximum"
        threshold           = "1"
        alarm_description   = "Triggers if nomis batch metric collected via /opt/textfile_monitoring is in error, see https://dsdmoj.atlassian.net/wiki/spaces/DSTT/pages/4295000327"
        alarm_actions       = ["dba"]
        ok_actions          = ["dba"]
        dimensions = {
          type          = "gauge"
          type_instance = "nomis_batch_failure_status"
        }
      }
    }
    db_xtag_out = {
      xtag-out-error = {
        comparison_operator = "GreaterThanOrEqualToThreshold"
        evaluation_periods  = "3"
        datapoints_to_alarm = "3"
        namespace           = "CWAgent"
        metric_name         = "collectd_textfile_monitoring_value"
        period              = "60"
        statistic           = "Maximum"
        threshold           = "1"
        alarm_description   = "Triggers if xtag out metric collected via /opt/textfile_monitoring is in error, see https://dsdmoj.atlassian.net/wiki/spaces/DSTT/pages/4295000327"
        alarm_actions       = ["dba"]
        ok_actions          = ["dba"]
        dimensions = {
          type          = "gauge"
          type_instance = "xtag_out_error"
        }
      }
    }
    db_textfile_metric_not_updated = {
      textfile-monitoring-metric-not-updated = {
        comparison_operator = "GreaterThanOrEqualToThreshold"
        evaluation_periods  = "1"
        datapoints_to_alarm = "1"
        namespace           = "CWAgent"
        metric_name         = "collectd_textfile_monitoring_seconds"
        period              = "300"
        statistic           = "Maximum"
        threshold           = "129600"
        treat_missing_data  = "breaching"
        alarm_description   = "Triggers if any metric in /opt/textfile_monitoring hasn't been updated for over 36 hours. See https://dsdmoj.atlassian.net/wiki/spaces/DSTT/pages/4325966186"
        alarm_actions       = ["pagerduty"]
        ok_actions          = ["pagerduty"]
      }
    }
    db_misload = {
      misload-script-error = {
        comparison_operator = "GreaterThanOrEqualToThreshold"
        evaluation_periods  = "3"
        datapoints_to_alarm = "3"
        namespace           = "CWAgent"
        metric_name         = "collectd_textfile_monitoring_value"
        period              = "60"
        statistic           = "Maximum"
        threshold           = "1"
        alarm_description   = "Triggers if misload script failed; metric collected via /opt/textfile_monitoring, see https://dsdmoj.atlassian.net/wiki/spaces/DSTT/pages/4295000327"
        alarm_actions       = ["dba"]
        ok_actions          = ["dba"]
        dimensions = {
          type          = "gauge"
          type_instance = "misload_status"
        }
      }
      misload-failed = {
        comparison_operator = "GreaterThanOrEqualToThreshold"
        evaluation_periods  = "3"
        datapoints_to_alarm = "3"
        namespace           = "CWAgent"
        metric_name         = "collectd_textfile_monitoring_value"
        period              = "60"
        statistic           = "Maximum"
        threshold           = "1"
        alarm_description   = "Triggers if misload_success_status metric collected via /opt/textfile_monitoring is in error, see https://dsdmoj.atlassian.net/wiki/spaces/DSTT/pages/4295000327"
        alarm_actions       = ["dba"]
        ok_actions          = ["dba"]
        dimensions = {
          type          = "gauge"
          type_instance = "misload_success_status"
        }
      }
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
        alarm_actions       = ["dba"]
        ok_actions          = ["dba"]
        dimensions = {
          type          = "duration"
          type_instance = "misload_running"
        }
      }
    }

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
