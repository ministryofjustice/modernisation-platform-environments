locals {
  instance_name_index = var.db_type == "primary" ? var.db_count_index : var.db_count_index + 1
  database_tag        = var.db_type == "primary" ? "${var.database_tag_prefix}_${var.db_type}db" : "${var.database_tag_prefix}_${var.db_type}db${var.db_count_index}"

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
        alarm_actions       = [var.sns_topic_arn]
        ok_actions          = [var.sns_topic_arn]
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
        alarm_actions       = [var.sns_topic_arn]
        ok_actions          = [var.sns_topic_arn]
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
        alarm_actions       = [var.sns_topic_arn]
        ok_actions          = [var.sns_topic_arn]
      }
      status-check-failed-attached-ebs = {
        comparison_operator = "GreaterThanOrEqualToThreshold"
        metric_name         = "StatusCheckFailed_AttachedEBS"
        namespace           = "AWS/EC2"
        period              = "60"
        statistic           = "Maximum"
        threshold           = "1"
        datapoints_to_alarm = "10"
        evaluation_periods  = "10"
        alarm_description   = "Triggers if there has been a status check failure for attached EBS volumes within the last 10 minutes."
        alarm_actions       = [var.sns_topic_arn]
        ok_actions          = [var.sns_topic_arn]
      }
    }
  }
}
