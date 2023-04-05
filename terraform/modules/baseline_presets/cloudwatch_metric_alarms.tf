# The cloudwatch_metric_alarms locals provides a standard set of 
# alarms useful for EC2 instances, autoscaling groups, load balancers etc. 
# grouped by namespace.
#
# The desired alarm_actions are passed in as a parameter to the module and 
# appended to the alarms in the output.  The alarms can also be optionally
# filtered in the output
#
# For example:
#
# options.cloudwatch_metric_alarms = {
#   alarms_without_actions = {}
#   standard_alarms = {
#     alarm_actions = ["sns_topic_name1", "sns_topic_name2"]
#     alarms_to_exclude = [
#       "instance-health-check-failed",
#     ]
#   }
#   critical_alarms = {
#     alarm_actions = ["sns_topic_name3"]
#     alarms_to_include = [
#       "instance-health-check-failed",
#     ]
#   }
# }
#
# output.cloudwatch_metric_alarms = {
#   alarms_without_actions = local.cloudwatch_metric_alarms  # as is, no actions defined
#   standard_alarms = {
#     acm = {
#       cert-expires-in-less-than-30-days = {
#         alarm_actions       = ["sns_topic_name1", "sns_topic_name2"]
#         comparison_operator = "LessThanThreshold"
#         ....
#       }
#       ...
#     }
#     ...
#   }
#   critical_alarms =  {
#     ec2 = {
#       instance-health-check-failed = {
#         alarm_actions = ["sns_topic_name3"]
#         ...
#       }
#     }
#   }
# }
#
# Add application specific alarms using exactly the same structure
# as local.cloudwatch_:etric_alarms using the application_alarms option.

locals {

  cloudwatch_metric_alarms = {

    acm = {
    }

    ec2 = {
      cpu-utilization = {
        comparison_operator = "GreaterThanOrEqualToThreshold" # threshold to trigger the alarm state
        evaluation_periods  = "15"                            # how many periods over which to evaluate the alarm
        datapoints_to_alarm = "15"                            # how many datapoints must be breaching the threshold to trigger the alarm
        metric_name         = "CPUUtilization"                # name of the alarm's associated metric   
        namespace           = "AWS/EC2"                       # namespace of the alarm's associated metric
        period              = "60"                            # period in seconds over which the specified statistic is applied
        statistic           = "Average"                       # could be Average/Minimum/Maximum etc.
        threshold           = "95"                            # threshold for the alarm - see comparison_operator for usage
        alarm_description   = "Triggers if the average cpu remains at 95% utilization or above for 15 minutes"
      }
      # Key Servers Instance alert - sensitive alert for key servers changing status from healthy. 
      # If this triggers often then we've got a problem.
      instance-health-check-failed = {
        comparison_operator = "GreaterThanOrEqualToThreshold"
        evaluation_periods  = "3"
        metric_name         = "StatusCheckFailed_Instance"
        namespace           = "AWS/EC2"
        period              = "60"
        statistic           = "Average"
        threshold           = "1"
        alarm_description   = "Instance status checks monitor the software and network configuration of your individual instance. When an instance status check fails, you typically must address the problem yourself: https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/monitoring-system-instance-status-check.html"
      }
      system-health-check-failed = {
        comparison_operator = "GreaterThanOrEqualToThreshold"
        evaluation_periods  = "3"
        metric_name         = "StatusCheckFailed_System"
        namespace           = "AWS/EC2"
        period              = "60"
        statistic           = "Average"
        threshold           = "1"
        alarm_description   = "System status checks monitor the AWS systems on which your instance runs. These checks detect underlying problems with your instance that require AWS involvement to repair: https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/monitoring-system-instance-status-check.html"
      }
    }

    ec2_cwagent_windows = {
      disk-free-windows = {
        comparison_operator = "LessThanOrEqualToThreshold"
        evaluation_periods  = "2"
        datapoints_to_alarm = "2"
        metric_name         = "DISK_FREE"
        namespace           = "CWAgent"
        period              = "60"
        statistic           = "Average"
        threshold           = "15"
        alarm_description   = "This metric monitors the amount of free disk space on the instance. If the amount of free disk space falls below 15% for 2 minutes, the alarm will trigger: https://dsdmoj.atlassian.net/wiki/spaces/DSTT/pages/4305453159/Disk+Free+alarm+-+Windows"
      }
      high-cpu-windows = {
        comparison_operator = "GreaterThanOrEqualToThreshold"
        evaluation_periods  = "5"
        datapoints_to_alarm = "5"
        metric_name         = "PROCESSOR_TIME"
        namespace           = "CWAgent"
        period              = "60"
        statistic           = "Average"
        threshold           = "95"
        alarm_description   = "This metric monitors the amount of free disk space on the instance. If the amount of free disk space falls below 15% for 2 minutes, the alarm will trigger: https://dsdmoj.atlassian.net/wiki/spaces/DSTT/pages/4305453159/Disk+Free+alarm+-+Windows"
      }
      low-available-memory-windows = {
        comparison_operator = "GreaterThanOrEqualToThreshold"
        evaluation_periods  = "2"
        datapoints_to_alarm = "2"
        metric_name         = "Memory % Committed Bytes In Use"
        namespace           = "CWAgent"
        period              = "60"
        statistic           = "Average"
        threshold           = "80"
        alarm_description   = "This metric monitors the amount of available memory. If Committed Bytes in Use is > 80% for 2 minutes, the alarm will trigger."
      }
    }

    ec2_cwagent_linux = {
      high-memory-usage = {
        comparison_operator = "GreaterThanOrEqualToThreshold"
        evaluation_periods  = "2"
        datapoints_to_alarm = "2"
        metric_name         = "mem_used_percent"
        namespace           = "CWAgent"
        period              = "60"
        statistic           = "Average"
        threshold           = "90"
        alarm_description   = "This metric monitors the amount of available memory. If the amount of available memory is greater than 90% for 2 minutes, the alarm will trigger."
      }
      cpu-usage-iowait = {
        comparison_operator = "GreaterThanOrEqualToThreshold"
        evaluation_periods  = "60"
        datapoints_to_alarm = "60"
        metric_name         = "cpu_usage_iowait"
        namespace           = "CWAgent"
        period              = "60"
        statistic           = "Average"
        threshold           = "30"
        alarm_description   = "This metric monitors the amount of CPU time spent waiting for I/O to complete. If the average CPU time spent waiting for I/O to complete is greater than 30% for 60 minutes, the alarm will trigger."
      }
      disk-used-percent = {
        comparison_operator = "GreaterThanOrEqualToThreshold"
        evaluation_periods  = "2"
        datapoints_to_alarm = "2"
        metric_name         = "disk_used_percent"
        namespace           = "CWAgent"
        period              = "60"
        statistic           = "Average"
        threshold           = "85"
        alarm_description   = "This metric monitors the amount of free disk space on the instance. If the amount of free disk space is above 85% for 2 minutes, the alarm will trigger: https://dsdmoj.atlassian.net/wiki/spaces/DSTT/pages/4289822860/Disk+Free+alarm+-+Linux"
      }
    }

    ec2_cwagent_collectd = {
      chronyd-service = {
        comparison_operator = "GreaterThanOrEqualToThreshold"
        evaluation_periods  = "3"
        namespace           = "CWAgent"
        metric_name         = "collectd_exec_value"
        period              = "60"
        statistic           = "Average"
        threshold           = "1"
        alarm_description   = "chronyd service has stopped"
        dimensions = {
          instance = "chronyd"
        }
      }
      sshd-service = {
        comparison_operator = "GreaterThanOrEqualToThreshold"
        evaluation_periods  = "3"
        namespace           = "CWAgent"
        metric_name         = "collectd_exec_value"
        period              = "60"
        statistic           = "Average"
        threshold           = "1"
        alarm_description   = "sshd service has stopped"
        dimensions = {
          instance = "sshd"
        }
      }
      cloudwatch-agent-status = {
        comparison_operator = "GreaterThanOrEqualToThreshold"
        evaluation_periods  = "3"
        namespace           = "CWAgent"
        metric_name         = "collectd_exec_value"
        period              = "60"
        statistic           = "Average"
        threshold           = "1"
        alarm_description   = "cloudwatch agent service has stopped"
        dimensions = {
          instance = "cloudwatch_agent_status"
        }
      }
      ssm-agent-status = {
        comparison_operator = "GreaterThanOrEqualToThreshold"
        evaluation_periods  = "3"
        namespace           = "CWAgent"
        metric_name         = "collectd_exec_value"
        period              = "60"
        statistic           = "Average"
        threshold           = "1"
        alarm_description   = "ssm agent service has stopped"
        dimensions = {
          instance = "ssm_agent_status"
        }
      }
    }
  }
}
