resource "aws_cloudwatch_metric_alarm" "disk_free_accessgate_temp" {
    alarm_name                = "${local.application_data.accounts[local.environment].short_env}-EBSDB-disk_free_DBF"
    alarm_description         = "This metric monitors the amount of free disk space on dbf mount. If the amount of free disk space on root falls below 20% for 2 minutes, the alarm will trigger"
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
      ImageId      = local.application_data.accounts[local.environment].accessgate_ami_id-1
      path         = "/temp"
      InstanceType = aws_instance.ec2_oracle_ebs.instance_type
      InstanceId   = aws_instance.ec2_oracle_ebs.id
      fstype       = "ext4"
      device       = "/dev/sdc"
    }

resource "aws_cloudwatch_metric_alarm" "disk_free_accessgate_home" {
    alarm_name                = "${local.application_data.accounts[local.environment].short_env}-EBSDB-disk_free_DBF"
    alarm_description         = "This metric monitors the amount of free disk space on dbf mount. If the amount of free disk space on root falls below 20% for 2 minutes, the alarm will trigger"
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
      ImageId      = local.application_data.accounts[local.environment].accessgate_ami_id-1
      path         = "/home"
      InstanceType = aws_instance.ec2_oracle_ebs.instance_type
      InstanceId   = aws_instance.ec2_oracle_ebs.id
      fstype       = "ext4"
      device       = "/dev/sdd"
    }

resource "aws_cloudwatch_metric_alarm" "disk_free_accessgate_u01" {
    alarm_name                = "${local.application_data.accounts[local.environment].short_env}-EBSDB-disk_free_DBF"
    alarm_description         = "This metric monitors the amount of free disk space on dbf mount. If the amount of free disk space on root falls below 20% for 2 minutes, the alarm will trigger"
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
      ImageId      = local.application_data.accounts[local.environment].accessgate_ami_id-1
      path         = "/u01"
      InstanceType = aws_instance.ec2_oracle_ebs.instance_type
      InstanceId   = aws_instance.ec2_oracle_ebs.id
      fstype       = "ext4"
      device       = "/dev/sdh"
    }