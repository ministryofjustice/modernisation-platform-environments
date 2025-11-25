resource "aws_cloudwatch_metric_alarm" "disk_free_ebsapps_temp" {
  count                     = local.application_data.accounts[local.environment].ebsapps_no_instances
  alarm_name                = "${local.application_data.accounts[local.environment].short_env}-ebs_apps${count.index + 1}-disk_free-temp"
  alarm_description         = "This metric monitors the amount of free disk space on /temp mount. If the amount of free disk space on root falls below 20% for 2 minutes, the alarm will trigger"
  comparison_operator       = "GreaterThanOrEqualToThreshold"
  metric_name               = "disk_used_percent"
  namespace                 = "CWAgent"
  statistic                 = "Average"
  insufficient_data_actions = []

  evaluation_periods  = local.application_data.cloudwatch_ec2.disk.eval_periods
  datapoints_to_alarm = local.application_data.cloudwatch_ec2.disk.eval_periods
  period              = local.application_data.cloudwatch_ec2.disk.period
  threshold           = local.application_data.cloudwatch_ec2.disk.threshold
  alarm_actions       = [aws_sns_topic.cw_alerts.arn]

  dimensions = {
    ImageId      = aws_instance.ec2_ebsapps[count.index].ami
    path         = "/temp"
    InstanceType = aws_instance.ec2_ebsapps[count.index].instance_type
    InstanceId   = aws_instance.ec2_ebsapps[count.index].id
    fstype       = "ext4"
    # device       = "nvme2n1" # "/dev/sdc"
  }
}

resource "aws_cloudwatch_metric_alarm" "disk_free_ebsapps_home" {
  count                     = local.application_data.accounts[local.environment].ebsapps_no_instances
  alarm_name                = "${local.application_data.accounts[local.environment].short_env}-ebs_apps${count.index + 1}-disk_free-home"
  alarm_description         = "This metric monitors the amount of free disk space on /home mount. If the amount of free disk space on root falls below 20% for 2 minutes, the alarm will trigger"
  comparison_operator       = "GreaterThanOrEqualToThreshold"
  metric_name               = "disk_used_percent"
  namespace                 = "CWAgent"
  statistic                 = "Average"
  insufficient_data_actions = []

  evaluation_periods  = local.application_data.cloudwatch_ec2.disk.eval_periods
  datapoints_to_alarm = local.application_data.cloudwatch_ec2.disk.eval_periods
  period              = local.application_data.cloudwatch_ec2.disk.period
  threshold           = local.application_data.cloudwatch_ec2.disk.threshold
  alarm_actions       = [aws_sns_topic.cw_alerts.arn]

  dimensions = {
    ImageId      = aws_instance.ec2_ebsapps[count.index].ami
    path         = "/home"
    InstanceType = aws_instance.ec2_ebsapps[count.index].instance_type
    InstanceId   = aws_instance.ec2_ebsapps[count.index].id
    fstype       = "ext4"
    # device       = "nvme6n1" # "/dev/sdd"
  }
}

resource "aws_cloudwatch_metric_alarm" "disk_free_ebsapps_export_home" {
  count                     = local.application_data.accounts[local.environment].ebsapps_no_instances
  alarm_name                = "${local.application_data.accounts[local.environment].short_env}-ebs_apps${count.index + 1}-disk_free-export_home"
  alarm_description         = "This metric monitors the amount of free disk space on /export/home mount. If the amount of free disk space on root falls below 20% for 2 minutes, the alarm will trigger"
  comparison_operator       = "GreaterThanOrEqualToThreshold"
  metric_name               = "disk_used_percent"
  namespace                 = "CWAgent"
  statistic                 = "Average"
  insufficient_data_actions = []

  evaluation_periods  = local.application_data.cloudwatch_ec2.disk.eval_periods
  datapoints_to_alarm = local.application_data.cloudwatch_ec2.disk.eval_periods
  period              = local.application_data.cloudwatch_ec2.disk.period
  threshold           = local.application_data.cloudwatch_ec2.disk.threshold
  alarm_actions       = [aws_sns_topic.cw_alerts.arn]

  dimensions = {
    ImageId      = aws_instance.ec2_ebsapps[count.index].ami
    path         = "/export/home"
    InstanceType = aws_instance.ec2_ebsapps[count.index].instance_type
    InstanceId   = aws_instance.ec2_ebsapps[count.index].id
    fstype       = "ext4"
    # device       = "nvme1n1" # "/dev/sdh"
  }
}

resource "aws_cloudwatch_metric_alarm" "disk_free_ebsapps_u01" {
  count                     = local.application_data.accounts[local.environment].ebsapps_no_instances
  alarm_name                = "${local.application_data.accounts[local.environment].short_env}-ebs_apps${count.index + 1}-disk_free-u01"
  alarm_description         = "This metric monitors the amount of free disk space on /u01 mount. If the amount of free disk space on root falls below 20% for 2 minutes, the alarm will trigger"
  comparison_operator       = "GreaterThanOrEqualToThreshold"
  metric_name               = "disk_used_percent"
  namespace                 = "CWAgent"
  statistic                 = "Average"
  insufficient_data_actions = []

  evaluation_periods  = local.application_data.cloudwatch_ec2.disk.eval_periods
  datapoints_to_alarm = local.application_data.cloudwatch_ec2.disk.eval_periods
  period              = local.application_data.cloudwatch_ec2.disk.period
  threshold           = local.application_data.cloudwatch_ec2.disk.threshold
  alarm_actions       = [aws_sns_topic.cw_alerts.arn]

  dimensions = {
    ImageId      = aws_instance.ec2_ebsapps[count.index].ami
    path         = "/u01"
    InstanceType = aws_instance.ec2_ebsapps[count.index].instance_type
    InstanceId   = aws_instance.ec2_ebsapps[count.index].id
    fstype       = "ext4"
    # device       = "nvme3n1" # "/dev/sdi"
  }
}

resource "aws_cloudwatch_metric_alarm" "disk_free_ebsapps_u03" {
  count                     = local.application_data.accounts[local.environment].ebsapps_no_instances
  alarm_name                = "${local.application_data.accounts[local.environment].short_env}-ebs_apps${count.index + 1}-disk_free-u03"
  alarm_description         = "This metric monitors the amount of free disk space on /u03 mount. If the amount of free disk space on root falls below 20% for 2 minutes, the alarm will trigger"
  comparison_operator       = "GreaterThanOrEqualToThreshold"
  metric_name               = "disk_used_percent"
  namespace                 = "CWAgent"
  statistic                 = "Average"
  insufficient_data_actions = []

  evaluation_periods  = local.application_data.cloudwatch_ec2.disk.eval_periods
  datapoints_to_alarm = local.application_data.cloudwatch_ec2.disk.eval_periods
  period              = local.application_data.cloudwatch_ec2.disk.period
  threshold           = local.application_data.cloudwatch_ec2.disk.threshold
  alarm_actions       = [aws_sns_topic.cw_alerts.arn]

  dimensions = {
    ImageId      = aws_instance.ec2_ebsapps[count.index].ami
    path         = "/u03"
    InstanceType = aws_instance.ec2_ebsapps[count.index].instance_type
    InstanceId   = aws_instance.ec2_ebsapps[count.index].id
    fstype       = "ext4"
    # device       = "nvme5n1" # "/dev/sdj"
  }
}

resource "aws_cloudwatch_metric_alarm" "disk_free_ebsapps_stage" {
  count                     = local.application_data.accounts[local.environment].ebsapps_no_instances
  alarm_name                = "${local.application_data.accounts[local.environment].short_env}-ebs_apps${count.index + 1}-disk_free-stage"
  alarm_description         = "This metric monitors the amount of free disk space on /stage mount. If the amount of free disk space on root falls below 20% for 2 minutes, the alarm will trigger"
  comparison_operator       = "GreaterThanOrEqualToThreshold"
  metric_name               = "disk_used_percent"
  namespace                 = "CWAgent"
  statistic                 = "Average"
  insufficient_data_actions = []

  evaluation_periods  = local.application_data.cloudwatch_ec2.disk.eval_periods
  datapoints_to_alarm = local.application_data.cloudwatch_ec2.disk.eval_periods
  period              = local.application_data.cloudwatch_ec2.disk.period
  threshold           = local.application_data.cloudwatch_ec2.disk.threshold
  alarm_actions       = [aws_sns_topic.cw_alerts.arn]

  dimensions = {
    ImageId      = aws_instance.ec2_ebsapps[count.index].ami
    path         = "/stage"
    InstanceType = aws_instance.ec2_ebsapps[count.index].instance_type
    InstanceId   = aws_instance.ec2_ebsapps[count.index].id
    fstype       = "ext4"
    # device       = "nvme8n1" # "/dev/sdk"
  }
}

resource "aws_cloudwatch_metric_alarm" "disk_free_ebsapps_backup_prod" {
  count                     = local.application_data.accounts[local.environment].ebsapps_no_instances
  alarm_name                = "${local.application_data.accounts[local.environment].short_env}-ebs_apps${count.index + 1}-disk_free-backup_prod"
  alarm_description         = "This metric monitors the amount of free disk space on /backup_prod mount. If the amount of free disk space on root falls below 20% for 2 minutes, the alarm will trigger"
  comparison_operator       = "GreaterThanOrEqualToThreshold"
  metric_name               = "disk_used_percent"
  namespace                 = "CWAgent"
  statistic                 = "Average"
  insufficient_data_actions = []

  evaluation_periods  = local.application_data.cloudwatch_ec2.disk.eval_periods
  datapoints_to_alarm = local.application_data.cloudwatch_ec2.disk.eval_periods
  period              = local.application_data.cloudwatch_ec2.disk.period
  threshold           = local.application_data.cloudwatch_ec2.disk.threshold
  alarm_actions       = [aws_sns_topic.cw_alerts.arn]

  dimensions = {
    ImageId      = aws_instance.ec2_ebsapps[count.index].ami
    path         = "/backup_prod"
    InstanceType = aws_instance.ec2_ebsapps[count.index].instance_type
    InstanceId   = aws_instance.ec2_ebsapps[count.index].id
    fstype       = "ext4"
    # device       = "nvme9n1" # "/dev/sdk"
  }
}