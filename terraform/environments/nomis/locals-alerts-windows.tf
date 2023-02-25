locals {
  cloudwatch_metric_alarms_windows = {
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
      alarm_actions       = [aws_sns_topic.nomis_nonprod_alarms.arn]
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
      alarm_actions       = [aws_sns_topic.nomis_nonprod_alarms.arn]
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
      alarm_actions       = [aws_sns_topic.nomis_nonprod_alarms.arn]
    }
  }
}