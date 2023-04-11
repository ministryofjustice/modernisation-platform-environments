# The cloudwatch_metric_alarms locals provides a standard set of
# alarms useful for EC2 instances, autoscaling groups, load balancers etc.
# grouped by namespace.
#
# Also see cloudwatch_metric_alarms_lists.tf
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

  cloudwatch_metric_alarms_application = var.options.cloudwatch_metric_alarms

  cloudwatch_metric_alarms_keys = keys(merge(
    local.cloudwatch_metric_alarms_application,
    local.cloudwatch_metric_alarms_baseline
  ))

  # deep merge application specific alarms with the baseline alarms
  cloudwatch_metric_alarms = {
    for key in local.cloudwatch_metric_alarms_keys : key => {
      for alarm_name in keys(merge(
        try(local.cloudwatch_metric_alarms_baseline[key], {}),
        try(local.cloudwatch_metric_alarms_application[key], {})
        )) : alarm_name => merge(
        try(local.cloudwatch_metric_alarms_baseline[key][alarm_name], {}),
        try(local.cloudwatch_metric_alarms_application[key][alarm_name], {})
      )
    }
  }

  # add common alarms here, grouped by namespace
  cloudwatch_metric_alarms_baseline = {

    acm = {
      cert-expires-in-less-than-14-days = {
        comparison_operator = "LessThanThreshold"
        evaluation_periods  = "1"
        datapoints_to_alarm = "1"
        metric_name         = "DaysToExpiry"
        namespace           = "AWS/CertificateManager"
        period              = "86400"
        statistic           = "Minimum"
        threshold           = "14"
        alarm_description   = "Triggers if an ACM certificate has not automatically renewed and is expiring soon. Automatic renewal should happen 60 days prior to expiration."
      }
    }

    ec2 = {
      cpu-utilization-high-15mins = {
        comparison_operator = "GreaterThanOrEqualToThreshold"
        evaluation_periods  = "15"
        datapoints_to_alarm = "15"
        metric_name         = "CPUUtilization"
        namespace           = "AWS/EC2"
        period              = "60"
        statistic           = "Maximum"
        threshold           = "95"
        alarm_description   = "Triggers if the average cpu remains at 95% utilization or above for 15 minutes"
      }
      instance-status-check-failed-in-last-hour = {
        comparison_operator = "GreaterThanOrEqualToThreshold"
        evaluation_periods  = "60"
        datapoints_to_alarm = "1"
        metric_name         = "StatusCheckFailed_Instance"
        namespace           = "AWS/EC2"
        period              = "60"
        statistic           = "Maximum"
        threshold           = "1"
        alarm_description   = "Triggers if there has been an instance status check failure within last hour. This monitors the software and network configuration of your individual instance. When an instance status check fails, you typically must address the problem yourself: https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/monitoring-system-instance-status-check.html"
      }
      system-status-check-failed-in-last-hour = {
        comparison_operator = "GreaterThanOrEqualToThreshold"
        evaluation_periods  = "60"
        datapoints_to_alarm = "1"
        metric_name         = "StatusCheckFailed_System"
        namespace           = "AWS/EC2"
        period              = "60"
        statistic           = "Maximum"
        threshold           = "1"
        alarm_description   = "Triggers if there has been a system status check failure within last hour.  This monitors the AWS systems on which your instance runs. These checks detect underlying problems with your instance that require AWS involvement to repair: https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/monitoring-system-instance-status-check.html"
      }
    }

    ec2_cwagent_windows = {
      free-disk-space-low-1hour = {
        comparison_operator = "LessThanOrEqualToThreshold"
        evaluation_periods  = "60"
        datapoints_to_alarm = "60"
        metric_name         = "DISK_FREE"
        namespace           = "CWAgent"
        period              = "60"
        statistic           = "Minimum"
        threshold           = "15"
        alarm_description   = "Triggers if free disk space falls below the threshold for an hour. See https://dsdmoj.atlassian.net/wiki/spaces/DSTT/pages/4305453159/Disk+Free+alarm+-+Windows"
      }
      high-memory-usage-15mins = {
        comparison_operator = "GreaterThanOrEqualToThreshold"
        evaluation_periods  = "15"
        datapoints_to_alarm = "15"
        metric_name         = "Memory % Committed Bytes In Use"
        namespace           = "CWAgent"
        period              = "60"
        statistic           = "Maximum"
        threshold           = "90"
        alarm_description   = "Triggers if memory usage is continually high for 15 minutes."
      }
    }

    ec2_cwagent_linux = {
      free-disk-space-low-1hour = {
        comparison_operator = "GreaterThanOrEqualToThreshold"
        evaluation_periods  = "60"
        datapoints_to_alarm = "60"
        metric_name         = "disk_used_percent"
        namespace           = "CWAgent"
        period              = "60"
        statistic           = "Maximum"
        threshold           = "85"
        alarm_description   = "Triggers if free disk space falls below the threshold for an hour. See https://dsdmoj.atlassian.net/wiki/spaces/DSTT/pages/4289822860/Disk+Free+alarm+-+Linux"
      }
      high-memory-usage-15mins = {
        comparison_operator = "GreaterThanOrEqualToThreshold"
        evaluation_periods  = "15"
        datapoints_to_alarm = "15"
        metric_name         = "mem_used_percent"
        namespace           = "CWAgent"
        period              = "60"
        statistic           = "Average"
        threshold           = "90"
        alarm_description   = "Triggers if memory usage is continually high for 15 minutes."
      }
      cpu-iowait-high-3hour = {
        comparison_operator = "GreaterThanOrEqualToThreshold"
        evaluation_periods  = "180"
        datapoints_to_alarm = "180"
        metric_name         = "cpu_usage_iowait"
        namespace           = "CWAgent"
        period              = "60"
        statistic           = "Maximum"
        threshold           = "30"
        alarm_description   = "Triggers if the amount of CPU time spent waiting for I/O to complete is continually high for 3 hours"
      }
    }

    ec2_cwagent_collectd = {
      chronyd-stopped = {
        comparison_operator = "GreaterThanOrEqualToThreshold"
        evaluation_periods  = "3"
        datapoints_to_alarm = "3"
        namespace           = "CWAgent"
        metric_name         = "collectd_exec_value"
        period              = "60"
        statistic           = "Maximum"
        threshold           = "1"
        alarm_description   = "Triggers if the chronyd service has stopped"
        dimensions = {
          instance = "chronyd"
        }
      }
      sshd-stopped = {
        comparison_operator = "GreaterThanOrEqualToThreshold"
        evaluation_periods  = "3"
        datapoints_to_alarm = "3"
        namespace           = "CWAgent"
        metric_name         = "collectd_exec_value"
        period              = "60"
        statistic           = "Maximum"
        threshold           = "1"
        alarm_description   = "Triggers if the sshd service has stopped"
        dimensions = {
          instance = "sshd"
        }
      }
      cloudwatch-agent-stopped = {
        comparison_operator = "GreaterThanOrEqualToThreshold"
        evaluation_periods  = "3"
        datapoints_to_alarm = "3"
        namespace           = "CWAgent"
        metric_name         = "collectd_exec_value"
        period              = "60"
        statistic           = "Maximum"
        threshold           = "1"
        alarm_description   = "Triggers if the cloudwatch agent service has stopped"
        dimensions = {
          instance = "cloudwatch_agent_status"
        }
      }
      ssm-agent-stopped = {
        comparison_operator = "GreaterThanOrEqualToThreshold"
        evaluation_periods  = "3"
        datapoints_to_alarm = "3"
        namespace           = "CWAgent"
        metric_name         = "collectd_exec_value"
        period              = "60"
        statistic           = "Maximum"
        threshold           = "1"
        alarm_description   = "Triggers if the ssm agent service has stopped"
        dimensions = {
          instance = "ssm_agent_status"
        }
      }
    }
    lb = {
      unhealthy-hosts-atleast-one = {
        comparison_operator = "GreaterThanOrEqualToThreshold"
        evaluation_periods  = "3"
        datapoints_to_alarm = "3"
        metric_name         = "UnHealthyHostCount"
        namespace           = "AWS/ApplicationELB"
        period              = "60"
        statistic           = "Average"
        threshold           = "1"
        alarm_description   = "Triggers if the number of unhealthy hosts in the target table group is at least one for 3 minutes"
      }
      unhealthy-hosts-atleast-two = {
        comparison_operator = "GreaterThanOrEqualToThreshold"
        evaluation_periods  = "3"
        datapoints_to_alarm = "3"
        metric_name         = "UnHealthyHostCount"
        namespace           = "AWS/ApplicationELB"
        period              = "60"
        statistic           = "Average"
        threshold           = "2"
        alarm_description   = "Triggers if the number of unhealthy hosts in the target table group is at least two for 3 minutes"
      }
    }
  }
}
