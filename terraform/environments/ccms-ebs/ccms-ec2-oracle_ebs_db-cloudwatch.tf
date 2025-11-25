resource "aws_cloudwatch_metric_alarm" "disk_free_ebsdb_ccms_ebs_redoa" {
  alarm_name                = "${local.application_data.accounts[local.environment].short_env}-ebs_db-disk_free-ccms_ebs_redoa"
  alarm_description         = "This metric monitors the amount of free disk space on /CCMS/EBS/redoA mount. If the amount of free disk space on root falls below 20% for 2 minutes, the alarm will trigger"
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
    ImageId      = aws_instance.ec2_oracle_ebs.ami
    path         = "/CCMS/EBS/redoA"
    InstanceType = aws_instance.ec2_oracle_ebs.instance_type
    InstanceId   = aws_instance.ec2_oracle_ebs.id
    fstype       = "ext4"
    # device       = "nvme2n1"
  }
}

#resource "aws_cloudwatch_metric_alarm" "disk_free_ebsdb_ccms_ebs_dbf" {
#  alarm_name                = "${local.application_data.accounts[local.environment].short_env}-ebs_db-disk_free-ccms_ebs_dbf"
#  alarm_description         = "This metric monitors the amount of free disk space on /CCMS/EBS/dbf mount. If the amount of free disk space on root falls below 20% for 2 minutes, the alarm will trigger"
#  comparison_operator       = "GreaterThanOrEqualToThreshold"
#  metric_name               = "disk_used_percent"
#  namespace                 = "CWAgent"
#  statistic                 = "Average"
#  insufficient_data_actions = []
#
#  evaluation_periods  = local.application_data.cloudwatch_ec2.disk.eval_periods
#  datapoints_to_alarm = local.application_data.cloudwatch_ec2.disk.eval_periods
#  period              = local.application_data.cloudwatch_ec2.disk.period
#  threshold           = local.application_data.cloudwatch_ec2.disk.threshold_dbf
#  alarm_actions       = [aws_sns_topic.cw_alerts.arn]
#
#  dimensions = {
#    ImageId      = aws_instance.ec2_oracle_ebs.ami
#    path         = "/CCMS/EBS/dbf" # local.application_data.accounts[local.environment].dbf_path
#    InstanceType = aws_instance.ec2_oracle_ebs.instance_type
#    InstanceId   = aws_instance.ec2_oracle_ebs.id
#    fstype       = "ext4"
#    device       = "nvme3n1" # local.application_data.accounts[local.environment].dbf_device
#  }
#}

resource "aws_cloudwatch_metric_alarm" "disk_free_ebsdb_ccms_ebs_arch" {
  alarm_name                = "${local.application_data.accounts[local.environment].short_env}-ebs_db-disk_free-ccms_ebs_arch"
  alarm_description         = "This metric monitors the amount of free disk space on /CCMS/EBS/arch mount. If the amount of free disk space on root falls below 20% for 2 minutes, the alarm will trigger"
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
    ImageId      = aws_instance.ec2_oracle_ebs.ami
    path         = "/CCMS/EBS/arch"
    InstanceType = aws_instance.ec2_oracle_ebs.instance_type
    InstanceId   = aws_instance.ec2_oracle_ebs.id
    fstype       = "ext4"
    # device       = "nvme4n1"
  }
}

resource "aws_cloudwatch_metric_alarm" "disk_free_ebsdb_backup" {
  alarm_name                = "${local.application_data.accounts[local.environment].short_env}-ebs_db-disk_free-backup"
  alarm_description         = "This metric monitors the amount of free disk space on /backup mount. If the amount of free disk space on root falls below 20% for 2 minutes, the alarm will trigger"
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
    ImageId      = aws_instance.ec2_oracle_ebs.ami
    path         = "/backup"
    InstanceType = aws_instance.ec2_oracle_ebs.instance_type
    InstanceId   = aws_instance.ec2_oracle_ebs.id
    fstype       = "ext4"
    # device       = "nvme5n1"
  }
}

resource "aws_cloudwatch_metric_alarm" "disk_free_ebsdb_temp" {
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
  threshold           = local.application_data.cloudwatch_ec2.disk.threshold
  alarm_actions       = [aws_sns_topic.cw_alerts.arn]

  dimensions = {
    ImageId      = aws_instance.ec2_oracle_ebs.ami
    path         = "/temp"
    InstanceType = aws_instance.ec2_oracle_ebs.instance_type
    InstanceId   = aws_instance.ec2_oracle_ebs.id
    fstype       = "ext4"
    # device       = "nvme6n1" # "/dev/sdc"
  }
}

resource "aws_cloudwatch_metric_alarm" "disk_free_ebsdb_ccms_ebs_diag" {
  alarm_name                = "${local.application_data.accounts[local.environment].short_env}-ebs_db-disk_free-ccms_ebs_diag"
  alarm_description         = "This metric monitors the amount of free disk space on /CCMS/EBS/diag mount. If the amount of free disk space on root falls below 20% for 2 minutes, the alarm will trigger"
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
    ImageId      = aws_instance.ec2_oracle_ebs.ami
    path         = "/CCMS/EBS/diag"
    InstanceType = aws_instance.ec2_oracle_ebs.instance_type
    InstanceId   = aws_instance.ec2_oracle_ebs.id
    fstype       = "ext4"
    # device       = "nvme7n1"
  }
}

resource "aws_cloudwatch_metric_alarm" "disk_free_ebsdb_ccms_ebs_redob" {
  alarm_name                = "${local.application_data.accounts[local.environment].short_env}-ebs_db-disk_free-ccms_ebs_redob"
  alarm_description         = "This metric monitors the amount of free disk space on /CCMS/EBS/redoB mount. If the amount of free disk space on root falls below 20% for 2 minutes, the alarm will trigger"
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
    ImageId      = aws_instance.ec2_oracle_ebs.ami
    path         = "/CCMS/EBS/redoB"
    InstanceType = aws_instance.ec2_oracle_ebs.instance_type
    InstanceId   = aws_instance.ec2_oracle_ebs.id
    fstype       = "ext4"
    # device       = "nvme8n1"
  }
}

resource "aws_cloudwatch_metric_alarm" "disk_free_ebsdb_home" {
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
  threshold           = local.application_data.cloudwatch_ec2.disk.threshold
  alarm_actions       = [aws_sns_topic.cw_alerts.arn]

  dimensions = {
    ImageId      = aws_instance.ec2_oracle_ebs.ami
    path         = "/home"
    InstanceType = aws_instance.ec2_oracle_ebs.instance_type
    InstanceId   = aws_instance.ec2_oracle_ebs.id
    fstype       = "ext4"
    # device       = "nvme9n1"
  }
}

resource "aws_cloudwatch_metric_alarm" "disk_free_ebsdb_backup_prod" {
  alarm_name                = "${local.application_data.accounts[local.environment].short_env}-ebs_db-disk_free-backup_prod"
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
    ImageId      = aws_instance.ec2_oracle_ebs.ami
    path         = "/backup_prod"
    InstanceType = aws_instance.ec2_oracle_ebs.instance_type
    InstanceId   = aws_instance.ec2_oracle_ebs.id
    fstype       = "ext4"
    # device       = "nvme10n1"
  }
}

resource "aws_cloudwatch_metric_alarm" "disk_free_ebsdb_u01" {
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
  threshold           = local.application_data.cloudwatch_ec2.disk.threshold
  alarm_actions       = [aws_sns_topic.cw_alerts.arn]

  dimensions = {
    ImageId      = aws_instance.ec2_oracle_ebs.ami
    path         = "/u01"
    InstanceType = aws_instance.ec2_oracle_ebs.instance_type
    InstanceId   = aws_instance.ec2_oracle_ebs.id
    fstype       = "ext4"
    # device       = "nvme11n1"
  }
}

resource "aws_cloudwatch_metric_alarm" "disk_free_ebsdb_export_home" {
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
  threshold           = local.application_data.cloudwatch_ec2.disk.threshold
  alarm_actions       = [aws_sns_topic.cw_alerts.arn]

  dimensions = {
    ImageId      = aws_instance.ec2_oracle_ebs.ami
    path         = "/export/home"
    InstanceType = aws_instance.ec2_oracle_ebs.instance_type
    InstanceId   = aws_instance.ec2_oracle_ebs.id
    fstype       = "ext4"
    # device       = "nvme12n1"
  }
}

resource "aws_cloudwatch_metric_alarm" "disk_free_ebsdb_ccms_ebs_techst" {
  alarm_name                = "${local.application_data.accounts[local.environment].short_env}-ebs_db-disk_free-ccms_ebs_techst"
  alarm_description         = "This metric monitors the amount of free disk space on /CCMS/EBS/techst mount. If the amount of free disk space on root falls below 20% for 2 minutes, the alarm will trigger"
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
    ImageId      = aws_instance.ec2_oracle_ebs.ami
    path         = "/CCMS/EBS/techst"
    InstanceType = aws_instance.ec2_oracle_ebs.instance_type
    InstanceId   = aws_instance.ec2_oracle_ebs.id
    fstype       = "ext4"
    # device       = "nvme13n1"
  }
}