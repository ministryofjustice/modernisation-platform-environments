locals {
  tags = merge(
    var.tags,
    {
      delius-environment = var.env_name
    },
  )

  vpc_name = "${var.account_info.business_unit}-${var.account_info.mp_environment}"

  cloudwatch_metric_alarms = {
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
        alarm_description   = "Triggers if the average cpu remains at 95% utilization or above for 15 minutes."
        alarm_actions       = [aws_sns_topic.delius_mis_alarms.arn]
        ok_actions          = [aws_sns_topic.delius_mis_alarms.arn]
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
        alarm_description   = "Triggers if there has been an instance status check failure within last hour. This monitors the software and network configuration of your individual instance."
        alarm_actions       = [aws_sns_topic.delius_mis_alarms.arn]
        ok_actions          = [aws_sns_topic.delius_mis_alarms.arn]
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
        alarm_description   = "Triggers if there has been a system status check failure within last hour.  This monitors the AWS systems on which your instance runs."
        alarm_actions       = [aws_sns_topic.delius_mis_alarms.arn]
        ok_actions          = [aws_sns_topic.delius_mis_alarms.arn]
      }
    }
    rclone_sync = {
      rclone-sync-error = {
        comparison_operator = "GreaterThanOrEqualToThreshold"
        evaluation_periods  = "3"
        datapoints_to_alarm = "3"
        namespace           = "CWAgent"
        metric_name         = "collectd_textfile_monitoring_rclone_sync_value"
        period              = "60"
        statistic           = "Maximum"
        threshold           = "1"
        alarm_description   = "Triggers if any metric collected via /opt/textfile_monitoring/rclone_sync is in error, See https://dsdmoj.atlassian.net/wiki/spaces/DSTT/pages/6319178819"
        alarm_actions       = [aws_sns_topic.delius_mis_alarms.arn]
        ok_actions          = [aws_sns_topic.delius_mis_alarms.arn]
      }
      rclone-sync-metric-not-updated = {
        comparison_operator = "GreaterThanOrEqualToThreshold"
        evaluation_periods  = "1"
        datapoints_to_alarm = "1"
        namespace           = "CWAgent"
        metric_name         = "collectd_textfile_monitoring_rclone_sync_seconds"
        period              = "300"
        statistic           = "Minimum"
        threshold           = "7200"
        treat_missing_data  = "breaching"
        alarm_description   = "Triggers if no metrics in /opt/textfile_monitoring/rclone_sync have been updated in the last 2 hours. See https://dsdmoj.atlassian.net/wiki/spaces/DSTT/pages/6319572194"
        alarm_actions       = [aws_sns_topic.delius_mis_alarms.arn]
        ok_actions          = [aws_sns_topic.delius_mis_alarms.arn]
      }
    }
  }
}
