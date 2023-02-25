locals {
  cloudwatch_metric_alarms_linux = {
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
      alarm_actions       = [aws_sns_topic.nomis_nonprod_alarms.arn]
    }
    cpu-usage-iowait = {
      comparison_operator = "GreaterThanOrEqualToThreshold"
      evaluation_periods  = "6"
      datapoints_to_alarm = "5"
      metric_name         = "cpu_usage_iowait"
      namespace           = "CWAgent"
      period              = "60"
      statistic           = "Average"
      threshold           = "90"
      alarm_description   = "This metric monitors the amount of CPU time spent waiting for I/O to complete. If the average CPU time spent waiting for I/O to complete is greater than 90% for 30 minutes, the alarm will trigger."
      alarm_actions       = [aws_sns_topic.nomis_nonprod_alarms.arn]
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
      alarm_actions       = [aws_sns_topic.nomis_nonprod_alarms.arn]
    }
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
      alarm_actions       = [aws_sns_topic.nomis_nonprod_alarms.arn] # SNS topic to send the alarm to
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
      alarm_actions       = [aws_sns_topic.nomis_nonprod_alarms.arn]
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
      alarm_actions       = [aws_sns_topic.nomis_nonprod_alarms.arn]
    }
    # Service alert - chronyd
    # Service alert - sshd
    # Service alert - cloudwatch_agent_status
    # Service alert - ssm_agent_status
  }
}