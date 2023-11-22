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
        alarm_description   = "Triggers if an ACM certificate has not automatically renewed and is expiring soon. Automatic renewal should happen 60 days prior to expiration."
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
        alarm_description   = "Triggers if the average cpu remains at 95% utilization or above for 15 minutes"
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
        alarm_description   = "Triggers if there has been an instance status check failure within last hour. This monitors the software and network configuration of your individual instance. When an instance status check fails, you typically must address the problem yourself: https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/monitoring-system-instance-status-check.html"
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
        alarm_description   = "Triggers if there has been a system status check failure within last hour.  This monitors the AWS systems on which your instance runs. These checks detect underlying problems with your instance that require AWS involvement to repair: https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/monitoring-system-instance-status-check.html"
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
        alarm_description   = "Triggers if free disk space falls below the threshold for an hour. See https://dsdmoj.atlassian.net/wiki/spaces/DSTT/pages/4305453159/Disk+Free+alarm+-+Windows"
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
        alarm_description   = "Triggers if memory usage is continually high for one hour"
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
        alarm_description   = "Triggers if free disk space falls below the threshold for an hour. See https://dsdmoj.atlassian.net/wiki/spaces/DSTT/pages/4289822860/Disk+Free+alarm+-+Linux"
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
        alarm_description   = "Triggers if memory usage is continually high for one hour"
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
        alarm_description   = "Triggers if the amount of CPU time spent waiting for I/O to complete is continually high for 3 hours"
        alarm_actions       = var.options.cloudwatch_metric_alarms_default_actions
      }
    }

    ec2_instance_cwagent_collectd_service_status = {
      service_status_error_os_layer = {
        comparison_operator = "GreaterThanOrEqualToThreshold"
        evaluation_periods  = "3"
        datapoints_to_alarm = "3"
        namespace           = "CWAgent"
        metric_name         = "collectd_service_status_os_value"
        period              = "60"
        statistic           = "Maximum"
        threshold           = "1"
        alarm_description   = "Triggers if an os-layer linux service such as chronyd or amazon-ssm-agent is stopped or in error. See collectd-service-metrics ansible role"
        alarm_actions       = var.options.cloudwatch_metric_alarms_default_actions
      }
      service_status_error_app_layer = {
        comparison_operator = "GreaterThanOrEqualToThreshold"
        evaluation_periods  = "3"
        datapoints_to_alarm = "3"
        namespace           = "CWAgent"
        metric_name         = "collectd_service_status_app_value"
        period              = "60"
        statistic           = "Maximum"
        threshold           = "1"
        alarm_description   = "Triggers if an application-layer linux service such as weblogic is stopped or in error. See collectd-service-metrics ansible role"
        alarm_actions       = var.options.cloudwatch_metric_alarms_default_actions
      }
    }
    ec2_instance_cwagent_collectd_connectivity_test = {
      connectivity_test_all_failed = {
        comparison_operator = "GreaterThanOrEqualToThreshold"
        evaluation_periods  = "3"
        datapoints_to_alarm = "3"
        namespace           = "CWAgent"
        metric_name         = "collectd_connectivity_test_value"
        period              = "60"
        statistic           = "Minimum"
        threshold           = "1"
        alarm_description   = "Triggers if all connectivity tests fail on a host. See connectivity-tests ec2 instance tag and collectd-connectivity-test ansible role"
        alarm_actions       = var.options.cloudwatch_metric_alarms_default_actions
      }
    }
    ec2_instance_cwagent_collectd_textfile_monitoring = {
      textfile_monitoring_metric_error = {
        comparison_operator = "GreaterThanOrEqualToThreshold"
        evaluation_periods  = "3"
        datapoints_to_alarm = "3"
        namespace           = "CWAgent"
        metric_name         = "collectd_textfile_monitoring_value"
        period              = "60"
        statistic           = "Maximum"
        threshold           = "1"
        alarm_description   = "Triggers if any metric collected via /opt/textfile_monitoring is in error, e.g. nomis batch or misload. See collectd-textfile-monitoring ansible role"
        alarm_actions       = var.options.cloudwatch_metric_alarms_default_actions
      }
      textfile_monitoring_metric_not_updated = {
        comparison_operator = "GreaterThanOrEqualToThreshold"
        evaluation_periods  = "1"
        datapoints_to_alarm = "1"
        namespace           = "CWAgent"
        metric_name         = "collectd_textfile_monitoring_seconds"
        period              = "300"
        statistic           = "Maximum"
        threshold           = "129600"
        treat_missing_data  = "breaching"
        alarm_description   = "Triggers if any metric in /opt/textfile_monitoring hasn't been updated for over 36 hours"
        alarm_actions       = var.options.cloudwatch_metric_alarms_default_actions
      }
    }
    ec2_instance_cwagent_collectd_oracle_db_connected = {
      oracle_db_disconnected = {
        comparison_operator = "GreaterThanOrEqualToThreshold"
        evaluation_periods  = "3"
        datapoints_to_alarm = "3"
        namespace           = "CWAgent"
        metric_name         = "collectd_oracle_db_connected_value"
        period              = "60"
        statistic           = "Maximum"
        threshold           = "1"
        alarm_description   = "Triggers if an oracle database is disconnected. See oracle-sids ec2 instance tag and collectd-oracle-db-connected ansible role"
        alarm_actions       = var.options.cloudwatch_metric_alarms_default_actions
      }
    }
    ec2_instance_cwagent_collectd_oracle_db_backup = {
      oracle_db_rman_backup_error = {
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
      oracle_db_rman_backup_did_not_run = {
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
        alarm_description   = "Triggers if the number of unhealthy hosts in the target table group is at least one for 3 minutes"
        alarm_actions       = var.options.cloudwatch_metric_alarms_default_actions
      }
    }
  }
}
