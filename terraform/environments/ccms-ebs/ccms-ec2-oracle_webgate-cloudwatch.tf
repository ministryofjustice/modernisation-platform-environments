resource "aws_cloudwatch_metric_alarm" "disk_free_webgate_temp" {
  count                     = local.application_data.accounts[local.environment].webgate_no_instances
  alarm_name                = "${local.application_data.accounts[local.environment].short_env}-webgate${count.index + 1}-disk_free-temp"
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
    ImageId      = aws_instance.ec2_webgate[count.index].ami # local.application_data.accounts[local.environment].webgate_ami_id-1
    path         = "/temp"
    InstanceType = aws_instance.ec2_webgate[count.index].instance_type
    InstanceId   = aws_instance.ec2_webgate[count.index].id
    fstype       = "ext4"
    device       = "nvme4n1" # "/dev/sdc"
  }
}

resource "aws_cloudwatch_metric_alarm" "disk_free_webgate_home" {
  count                     = local.application_data.accounts[local.environment].webgate_no_instances
  alarm_name                = "${local.application_data.accounts[local.environment].short_env}-webgate${count.index + 1}-disk_free-home"
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
    ImageId      = aws_instance.ec2_webgate[count.index].ami # local.application_data.accounts[local.environment].webgate_ami_id-1
    path         = "/home"
    InstanceType = aws_instance.ec2_webgate[count.index].instance_type
    InstanceId   = aws_instance.ec2_webgate[count.index].id
    fstype       = "ext4"
    device       = "nvme2n1" # "/dev/sdd"
  }
}

resource "aws_cloudwatch_metric_alarm" "disk_free_webgate_ccms" {
  count                     = local.application_data.accounts[local.environment].webgate_no_instances
  alarm_name                = "${local.application_data.accounts[local.environment].short_env}-webgate${count.index + 1}-disk_free-ccms"
  alarm_description         = "This metric monitors the amount of free disk space on /CCMS mount. If the amount of free disk space on root falls below 20% for 2 minutes, the alarm will trigger"
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
    ImageId      = aws_instance.ec2_webgate[count.index].ami # local.application_data.accounts[local.environment].webgate_ami_id-1
    path         = "/CCMS"
    InstanceType = aws_instance.ec2_webgate[count.index].instance_type
    InstanceId   = aws_instance.ec2_webgate[count.index].id
    fstype       = "ext4"
    device       = "nvme3n1" # "/dev/sdh"
  }
}