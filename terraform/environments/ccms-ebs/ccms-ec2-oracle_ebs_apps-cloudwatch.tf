resource "aws_cloudwatch_metric_alarm" "disk_free_ebsapps_temp" {
  alarm_name                = "${local.application_data.accounts[local.environment].short_env}-ebs_db-disk_free-temp"
  alarm_description         = "This metric monitors the amount of free disk space on /temp mount. If the amount of free disk space on root falls below 20% for 2 minutes, the alarm will trigger"
  comparison_operator       = "GreaterThanOrEqualToThreshold"
  metric_name               = "disk_used_percent"
  namespace                 = "CWAgent"
  statistic                 = "Average"
  insufficient_data_actions = []

  evaluation_periods  = local.application_data.cloudwatch_ec2.disk.eval_periods
  datapoints_to_alarm = local.application_data.cloudwatch_ec2.disk.eval_periods
  period              = local.application_data.cloudwatch_ec2.disk.period
  threshold           = local.application_data.cloudwatch_ec2.disk.threshold_dbf
  alarm_actions       = [aws_sns_topic.cw_alerts.arn]

  dimensions = {
    ImageId      = aws_instance.ec2_oracle_ebs.ami
    path         = "/temp"
    InstanceType = aws_instance.ec2_oracle_ebs.instance_type
    InstanceId   = aws_instance.ec2_oracle_ebs.id
    fstype       = "ext4"
    device       = "/dev/sdc"
  }
}

resource "aws_cloudwatch_metric_alarm" "disk_free_ebsapps_home" {
  alarm_name                = "${local.application_data.accounts[local.environment].short_env}-ebs_db-disk_free-home"
  alarm_description         = "This metric monitors the amount of free disk space on /home mount. If the amount of free disk space on root falls below 20% for 2 minutes, the alarm will trigger"
  comparison_operator       = "GreaterThanOrEqualToThreshold"
  metric_name               = "disk_used_percent"
  namespace                 = "CWAgent"
  statistic                 = "Average"
  insufficient_data_actions = []

  evaluation_periods  = local.application_data.cloudwatch_ec2.disk.eval_periods
  datapoints_to_alarm = local.application_data.cloudwatch_ec2.disk.eval_periods
  period              = local.application_data.cloudwatch_ec2.disk.period
  threshold           = local.application_data.cloudwatch_ec2.disk.threshold_dbf
  alarm_actions       = [aws_sns_topic.cw_alerts.arn]

  dimensions = {
    ImageId      = aws_instance.ec2_oracle_ebs.ami
    path         = "/home"
    InstanceType = aws_instance.ec2_oracle_ebs.instance_type
    InstanceId   = aws_instance.ec2_oracle_ebs.id
    fstype       = "ext4"
    device       = "/dev/sdd"
  }
}

resource "aws_cloudwatch_metric_alarm" "disk_free_ebsapps_export_home" {
  alarm_name                = "${local.application_data.accounts[local.environment].short_env}-ebs_db-disk_free-export_home"
  alarm_description         = "This metric monitors the amount of free disk space on /export/home mount. If the amount of free disk space on root falls below 20% for 2 minutes, the alarm will trigger"
  comparison_operator       = "GreaterThanOrEqualToThreshold"
  metric_name               = "disk_used_percent"
  namespace                 = "CWAgent"
  statistic                 = "Average"
  insufficient_data_actions = []

  evaluation_periods  = local.application_data.cloudwatch_ec2.disk.eval_periods
  datapoints_to_alarm = local.application_data.cloudwatch_ec2.disk.eval_periods
  period              = local.application_data.cloudwatch_ec2.disk.period
  threshold           = local.application_data.cloudwatch_ec2.disk.threshold_dbf
  alarm_actions       = [aws_sns_topic.cw_alerts.arn]

  dimensions = {
    ImageId      = aws_instance.ec2_oracle_ebs.ami
    path         = "/export/home"
    InstanceType = aws_instance.ec2_oracle_ebs.instance_type
    InstanceId   = aws_instance.ec2_oracle_ebs.id
    fstype       = "ext4"
    device       = "/dev/sdh"
  }
}

resource "aws_cloudwatch_metric_alarm" "disk_free_ebsapps_u01" {
  alarm_name                = "${local.application_data.accounts[local.environment].short_env}-ebs_db-disk_free-u01"
  alarm_description         = "This metric monitors the amount of free disk space on /u01 mount. If the amount of free disk space on root falls below 20% for 2 minutes, the alarm will trigger"
  comparison_operator       = "GreaterThanOrEqualToThreshold"
  metric_name               = "disk_used_percent"
  namespace                 = "CWAgent"
  statistic                 = "Average"
  insufficient_data_actions = []

  evaluation_periods  = local.application_data.cloudwatch_ec2.disk.eval_periods
  datapoints_to_alarm = local.application_data.cloudwatch_ec2.disk.eval_periods
  period              = local.application_data.cloudwatch_ec2.disk.period
  threshold           = local.application_data.cloudwatch_ec2.disk.threshold_dbf
  alarm_actions       = [aws_sns_topic.cw_alerts.arn]

  dimensions = {
    ImageId      = aws_instance.ec2_oracle_ebs.ami
    path         = "/u01"
    InstanceType = aws_instance.ec2_oracle_ebs.instance_type
    InstanceId   = aws_instance.ec2_oracle_ebs.id
    fstype       = "ext4"
    device       = "/dev/sdi"
  }
}

resource "aws_cloudwatch_metric_alarm" "disk_free_ebsapps_u03" {
  alarm_name                = "${local.application_data.accounts[local.environment].short_env}-ebs_db-disk_free-u03"
  alarm_description         = "This metric monitors the amount of free disk space on /u03 mount. If the amount of free disk space on root falls below 20% for 2 minutes, the alarm will trigger"
  comparison_operator       = "GreaterThanOrEqualToThreshold"
  metric_name               = "disk_used_percent"
  namespace                 = "CWAgent"
  statistic                 = "Average"
  insufficient_data_actions = []

  evaluation_periods  = local.application_data.cloudwatch_ec2.disk.eval_periods
  datapoints_to_alarm = local.application_data.cloudwatch_ec2.disk.eval_periods
  period              = local.application_data.cloudwatch_ec2.disk.period
  threshold           = local.application_data.cloudwatch_ec2.disk.threshold_dbf
  alarm_actions       = [aws_sns_topic.cw_alerts.arn]

  dimensions = {
    ImageId      = aws_instance.ec2_oracle_ebs.ami
    path         = "/u03"
    InstanceType = aws_instance.ec2_oracle_ebs.instance_type
    InstanceId   = aws_instance.ec2_oracle_ebs.id
    fstype       = "ext4"
    device       = "/dev/sdj"
  }
}

resource "aws_cloudwatch_metric_alarm" "disk_free_ebsapps_stage" {
  alarm_name                = "${local.application_data.accounts[local.environment].short_env}-ebs_db-disk_free-stage"
  alarm_description         = "This metric monitors the amount of free disk space on /stage mount. If the amount of free disk space on root falls below 20% for 2 minutes, the alarm will trigger"
  comparison_operator       = "GreaterThanOrEqualToThreshold"
  metric_name               = "disk_used_percent"
  namespace                 = "CWAgent"
  statistic                 = "Average"
  insufficient_data_actions = []

  evaluation_periods  = local.application_data.cloudwatch_ec2.disk.eval_periods
  datapoints_to_alarm = local.application_data.cloudwatch_ec2.disk.eval_periods
  period              = local.application_data.cloudwatch_ec2.disk.period
  threshold           = local.application_data.cloudwatch_ec2.disk.threshold_dbf
  alarm_actions       = [aws_sns_topic.cw_alerts.arn]

  dimensions = {
    ImageId      = aws_instance.ec2_oracle_ebs.ami
    path         = "/stage"
    InstanceType = aws_instance.ec2_oracle_ebs.instance_type
    InstanceId   = aws_instance.ec2_oracle_ebs.id
    fstype       = "ext4"
    device       = "/dev/sdk"
  }
}