# The cloudwatch_metric_alarms locals provides a standard set of
# alarms useful for EC2 instances, autoscaling groups, load balancers etc.
# grouped by namespace.
#
# Example alarm definition with comment.  The statistic may be applied over
# several instances in the case of auto scaling groups.
#   cpu-utilization-high-15mins = {
#     comparison_operator = "GreaterThanOrEqualToThreshold" # threshold to trigger the alarm state
#     evaluation_periods  = "15"                            # how many periods over which to evaluate the alarm
#     datapoints_to_alarm = "15"                            # how many datapoints must be breaching the threshold to trigger the alarm
#     metric_name         = "CPUUtilization"                # name of the alarm's associated metric
#     namespace           = "AWS/EC2"                       # namespace of the alarm's associated metric
#     period              = "60"                            # period in seconds over which the specified statistic is applied
#     statistic           = "Average"                       # could be Average/Minimum/Maximum etc.
#     threshold           = "95"                            # threshold for the alarm - see comparison_operator for usage
#     alarm_description   = "Triggers if the average cpu remains at 95% utilization or above for 15 minutes"
#   }

locals {

  # add common alarms here, grouped by namespace
  cloudwatch_metric_alarms = {

    acm = {
      cert-expires-soon = {
        comparison_operator = "LessThanThreshold"
        evaluation_periods  = "1"
        datapoints_to_alarm = "1"
        metric_name         = "DaysToExpiry"
        namespace           = "AWS/CertificateManager"
        period              = "86400"
        statistic           = "Minimum"
        threshold           = "14"
        alarm_description   = "Triggers if an ACM certificate has not automatically renewed and is expiring soon. Automatic renewal should happen 60 days prior to expiration. See https://dsdmoj.atlassian.net/wiki/spaces/DSTT/pages/4615340266"
        alarm_actions       = var.options.cloudwatch_metric_alarms_default_actions
      }
    }

    ec2 = {
      cpu-utilization-high = {
        comparison_operator = "GreaterThanOrEqualToThreshold"
        evaluation_periods  = "15"
        datapoints_to_alarm = "15"
        metric_name         = "CPUUtilization"
        namespace           = "AWS/EC2"
        period              = "60"
        statistic           = "Maximum"
        threshold           = "95"
        alarm_description   = "Triggers if the average cpu remains at 95% utilization or above for 15 minutes. See https://dsdmoj.atlassian.net/wiki/spaces/DSTT/pages/4326064583"
        alarm_actions       = var.options.cloudwatch_metric_alarms_default_actions
      }
      instance-status-check-failed = {
        comparison_operator = "GreaterThanOrEqualToThreshold"
        evaluation_periods  = "60"
        datapoints_to_alarm = "1"
        metric_name         = "StatusCheckFailed_Instance"
        namespace           = "AWS/EC2"
        period              = "60"
        statistic           = "Maximum"
        threshold           = "1"
        alarm_description   = "Triggers if there has been an instance status check failure within last hour. This monitors the software and network configuration of your individual instance. See https://dsdmoj.atlassian.net/wiki/spaces/DSTT/pages/4326491009"
        alarm_actions       = var.options.cloudwatch_metric_alarms_default_actions
      }
      system-status-check-failed = {
        comparison_operator = "GreaterThanOrEqualToThreshold"
        evaluation_periods  = "60"
        datapoints_to_alarm = "1"
        metric_name         = "StatusCheckFailed_System"
        namespace           = "AWS/EC2"
        period              = "60"
        statistic           = "Maximum"
        threshold           = "1"
        alarm_description   = "Triggers if there has been a system status check failure within last hour.  This monitors the AWS systems on which your instance runs. See https://dsdmoj.atlassian.net/wiki/spaces/DSTT/pages/4326359363"
        alarm_actions       = var.options.cloudwatch_metric_alarms_default_actions
      }
    }

    ec2_cwagent_windows = {
      free-disk-space-low = {
        comparison_operator = "LessThanOrEqualToThreshold"
        evaluation_periods  = "60"
        datapoints_to_alarm = "60"
        metric_name         = "DISK_FREE"
        namespace           = "CWAgent"
        period              = "60"
        statistic           = "Minimum"
        threshold           = "15"
        alarm_description   = "Triggers if free disk space falls below the threshold for an hour. See https://dsdmoj.atlassian.net/wiki/spaces/DSTT/pages/4289822860"
        alarm_actions       = var.options.cloudwatch_metric_alarms_default_actions
      }
      high-memory-usage = {
        comparison_operator = "GreaterThanOrEqualToThreshold"
        evaluation_periods  = "60"
        datapoints_to_alarm = "60"
        metric_name         = "Memory % Committed Bytes In Use"
        namespace           = "CWAgent"
        period              = "60"
        statistic           = "Maximum"
        threshold           = "95"
        alarm_description   = "Triggers if memory usage is continually high for one hour. See https://dsdmoj.atlassian.net/wiki/spaces/DSTT/pages/4326523370"
        alarm_actions       = var.options.cloudwatch_metric_alarms_default_actions
      }
      instance-or-cloudwatch-agent-stopped = {
        comparison_operator = "LessThanOrEqualToThreshold"
        evaluation_periods  = "5"
        datapoints_to_alarm = "5"
        metric_name         = "CPU_IDLE"
        period              = "60"
        namespace           = "CWAgent"
        statistic           = "SampleCount"
        threshold           = "0"
        treat_missing_data  = "breaching"
        alarm_description   = "Triggers if the instance or cloudwatch agent is stopped after 5 minutes since the metric will not be collected. See https://dsdmoj.atlassian.net/wiki/spaces/DSTT/pages/4671340764/EC2+instance-or-cloudwatch-agent-stopped+alarm"
        alarm_actions       = var.options.cloudwatch_metric_alarms_default_actions
      }
    }

    ec2_cwagent_linux = {
      free-disk-space-low = {
        comparison_operator = "GreaterThanOrEqualToThreshold"
        evaluation_periods  = "60"
        datapoints_to_alarm = "60"
        metric_name         = "disk_used_percent"
        namespace           = "CWAgent"
        period              = "60"
        statistic           = "Maximum"
        threshold           = "85"
        alarm_description   = "Triggers if free disk space falls below the threshold for an hour. See https://dsdmoj.atlassian.net/wiki/spaces/DSTT/pages/4289822860"
        alarm_actions       = var.options.cloudwatch_metric_alarms_default_actions
      }
      high-memory-usage = {
        comparison_operator = "GreaterThanOrEqualToThreshold"
        evaluation_periods  = "60"
        datapoints_to_alarm = "60"
        metric_name         = "mem_used_percent"
        namespace           = "CWAgent"
        period              = "60"
        statistic           = "Average"
        threshold           = "95"
        alarm_description   = "Triggers if memory usage is continually high for one hour. See https://dsdmoj.atlassian.net/wiki/spaces/DSTT/pages/4326523370"
        alarm_actions       = var.options.cloudwatch_metric_alarms_default_actions
      }
      cpu-iowait-high = {
        comparison_operator = "GreaterThanOrEqualToThreshold"
        evaluation_periods  = "180"
        datapoints_to_alarm = "180"
        metric_name         = "cpu_usage_iowait"
        namespace           = "CWAgent"
        period              = "60"
        statistic           = "Maximum"
        threshold           = "40"
        alarm_description   = "Triggers if the amount of CPU time spent waiting for I/O to complete is continually high for 3 hours. See https://dsdmoj.atlassian.net/wiki/spaces/DSTT/pages/4325900634"
        alarm_actions       = var.options.cloudwatch_metric_alarms_default_actions
      }
      instance-or-cloudwatch-agent-stopped = {
        comparison_operator = "LessThanOrEqualToThreshold"
        evaluation_periods  = "5"
        datapoints_to_alarm = "5"
        metric_name         = "cpu_usage_idle"
        period              = "60"
        namespace           = "CWAgent"
        statistic           = "SampleCount"
        threshold           = "0"
        treat_missing_data  = "breaching"
        alarm_description   = "Triggers if the instance or cloudwatch agent is stopped after 5 minutes since the metric will not be collected. See https://dsdmoj.atlassian.net/wiki/spaces/DSTT/pages/4671340764/EC2+instance-or-cloudwatch-agent-stopped+alarm"
        alarm_actions       = var.options.cloudwatch_metric_alarms_default_actions
      }
    }

    ec2_instance_cwagent_collectd_service_status_os = {
      service-status-error-os-layer = {
        comparison_operator = "GreaterThanOrEqualToThreshold"
        evaluation_periods  = "3"
        datapoints_to_alarm = "3"
        namespace           = "CWAgent"
        metric_name         = "collectd_service_status_os_value"
        period              = "60"
        statistic           = "Maximum"
        threshold           = "1"
        alarm_description   = "Triggers if an os-layer linux service such as chronyd or amazon-ssm-agent is stopped or in error. See https://dsdmoj.atlassian.net/wiki/spaces/DSTT/pages/4615406350"
        alarm_actions       = var.options.cloudwatch_metric_alarms_default_actions
      }
    }
    ec2_instance_cwagent_collectd_service_status_app = {
      service-status-error-app-layer = {
        comparison_operator = "GreaterThanOrEqualToThreshold"
        evaluation_periods  = "3"
        datapoints_to_alarm = "3"
        namespace           = "CWAgent"
        metric_name         = "collectd_service_status_app_value"
        period              = "60"
        statistic           = "Maximum"
        threshold           = "1"
        alarm_description   = "Triggers if an application-layer linux service such as weblogic is stopped or in error. See https://dsdmoj.atlassian.net/wiki/spaces/DSTT/pages/4615406362"
        alarm_actions       = var.options.cloudwatch_metric_alarms_default_actions
      }
    }
    ec2_instance_cwagent_collectd_connectivity_test = {
      connectivity-test-all-failed = {
        comparison_operator = "GreaterThanOrEqualToThreshold"
        evaluation_periods  = "3"
        datapoints_to_alarm = "3"
        namespace           = "CWAgent"
        metric_name         = "collectd_connectivity_test_value"
        period              = "60"
        statistic           = "Minimum"
        threshold           = "1"
        alarm_description   = "Triggers if all netcat tests defined by connectivity-tests tag fail. See https://dsdmoj.atlassian.net/wiki/spaces/DSTT/pages/4615274774"
        alarm_actions       = var.options.cloudwatch_metric_alarms_default_actions
      }
    }
    ec2_instance_cwagent_collectd_textfile_monitoring = {
      textfile-monitoring-metric-error = {
        comparison_operator = "GreaterThanOrEqualToThreshold"
        evaluation_periods  = "3"
        datapoints_to_alarm = "3"
        namespace           = "CWAgent"
        metric_name         = "collectd_textfile_monitoring_value"
        period              = "60"
        statistic           = "Maximum"
        threshold           = "1"
        alarm_description   = "Triggers if any metric collected via /opt/textfile_monitoring is in error, e.g. nomis batch or misload. See https://dsdmoj.atlassian.net/wiki/spaces/DSTT/pages/4295000327"
        alarm_actions       = var.options.cloudwatch_metric_alarms_default_actions
      }
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
        alarm_actions       = var.options.cloudwatch_metric_alarms_default_actions
      }
    }
    ec2_instance_cwagent_collectd_oracle_db_connected = {
      oracle-db-disconnected = {
        comparison_operator = "GreaterThanOrEqualToThreshold"
        evaluation_periods  = "3"
        datapoints_to_alarm = "3"
        namespace           = "CWAgent"
        metric_name         = "collectd_oracle_db_connected_value"
        period              = "60"
        statistic           = "Maximum"
        threshold           = "1"
        alarm_description   = "Triggers if an oracle database defined in oracle-sids tag is disconnected. See https://dsdmoj.atlassian.net/wiki/spaces/DSTT/pages/4294246698"
        alarm_actions       = var.options.cloudwatch_metric_alarms_default_actions
      }
    }
    ec2_instance_cwagent_collectd_oracle_db_backup = {
      oracle-db-rman-backup-error = {
        comparison_operator = "GreaterThanOrEqualToThreshold"
        evaluation_periods  = "1"
        datapoints_to_alarm = "1"
        namespace           = "CWAgent"
        metric_name         = "collectd_textfile_monitoring_rman_backup_value"
        period              = "300"
        statistic           = "Maximum"
        threshold           = "1"
        alarm_description   = "Triggers if a scheduled oracle rman db backup has failed. See collectd-textfile-monitoring and oracle-db-backup role"
        alarm_actions       = var.options.cloudwatch_metric_alarms_default_actions
      }
      oracle-db-rman-backup-did-not-run = {
        comparison_operator = "GreaterThanOrEqualToThreshold"
        evaluation_periods  = "1"
        datapoints_to_alarm = "1"
        namespace           = "CWAgent"
        metric_name         = "collectd_textfile_monitoring_rman_backup_seconds"
        period              = "300"
        statistic           = "Maximum"
        threshold           = "129600"
        treat_missing_data  = "breaching"
        alarm_description   = "Triggers if rman_backup metric not collected or not updated for over 36 hours"
        alarm_actions       = var.options.cloudwatch_metric_alarms_default_actions
      }
    }
    lb = {
      unhealthy-load-balancer-host = {
        comparison_operator = "GreaterThanOrEqualToThreshold"
        evaluation_periods  = "3"
        datapoints_to_alarm = "3"
        metric_name         = "UnHealthyHostCount"
        namespace           = "AWS/ApplicationELB"
        period              = "60"
        statistic           = "Average"
        threshold           = "1"
        alarm_description   = "Triggers if the number of unhealthy hosts in the target table group is at least one for 3 minutes. See https://dsdmoj.atlassian.net/wiki/spaces/DSTT/pages/4615340278"
        alarm_actions       = var.options.cloudwatch_metric_alarms_default_actions
      }
    }
  }
}
