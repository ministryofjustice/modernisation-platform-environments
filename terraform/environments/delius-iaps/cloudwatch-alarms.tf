# SNS topic for monitoring to send alarms to
resource "aws_sns_topic" "this" {
  name = "${local.application_name}-alerting"
}

// ASG Alarms
resource "aws_cloudwatch_metric_alarm" "asg_cpu_utilization_over_threshold" {
  alarm_name                = "${local.application_name}-asg-cpu-utilization-over-threshold"
  comparison_operator       = "GreaterThanOrEqualToThreshold"
  evaluation_periods        = "2"
  metric_name               = "CPUUtilization"
  namespace                 = "AWS/EC2"
  period                    = "120"
  statistic                 = "Average"
  threshold                 = "80"
  alarm_actions             = [aws_sns_topic.this.arn]
  ok_actions                = [aws_sns_topic.this.arn]
  alarm_description         = "IAPs ASG CPU Utilization is greater than 80%"
  insufficient_data_actions = []
  tags                      = local.tags

  dimensions = {
    AutoScalingGroupName = module.ec2_iaps_server.autoscaling_group_name
  }
}

resource "aws_cloudwatch_metric_alarm" "asg_failed_status_checks" {
  alarm_name                = "${local.application_name}-asg-failed-status-checks"
  comparison_operator       = "GreaterThanOrEqualToThreshold"
  evaluation_periods        = "1"
  metric_name               = "StatusCheckFailed"
  namespace                 = "AWS/EC2"
  period                    = "300"
  statistic                 = "Average"
  threshold                 = "1"
  alarm_actions             = [aws_sns_topic.this.arn]
  ok_actions                = [aws_sns_topic.this.arn]
  alarm_description         = "EC2 StatusCheckFailed for one or more instances in the IAPS ASG"
  insufficient_data_actions = []
  tags                      = local.tags

  dimensions = {
    AutoScalingGroupName = module.ec2_iaps_server.autoscaling_group_name
  }
}

resource "aws_cloudwatch_metric_alarm" "in_service_instances_below_threshold" {
  alarm_name                = "${local.application_name}-asg-in-service-instances"
  comparison_operator       = "LessThanThreshold"
  evaluation_periods        = "1"
  metric_name               = "GroupInServiceInstances"
  namespace                 = "AWS/AutoScaling"
  period                    = "300"
  statistic                 = "Average"
  threshold                 = "1"
  alarm_actions             = [aws_sns_topic.this.arn]
  ok_actions                = [aws_sns_topic.this.arn]
  alarm_description         = "There is less than 1 instance InService for ec2 IAPS ASG"
  insufficient_data_actions = []
  tags                      = local.tags

  dimensions = {
    AutoScalingGroupName = module.ec2_iaps_server.autoscaling_group_name
  }
}


// RDS Alarms
resource "aws_cloudwatch_metric_alarm" "rds_cpu_utilization_over_threshold" {
  alarm_name          = "${local.application_name}-rds-cpu-utilization-over-threshold"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = "2"
  metric_name         = "CPUUtilization"
  namespace           = "AWS/RDS"
  period              = "300"
  statistic           = "Average"
  threshold           = "80"
  alarm_description   = "This metric monitors CPU utilization for the RDS instance"
  alarm_actions       = [aws_sns_topic.this.arn]
  ok_actions          = [aws_sns_topic.this.arn]
  dimensions = {
    DBInstanceIdentifier = aws_db_instance.iaps.identifier
  }
}

resource "aws_cloudwatch_metric_alarm" "rds_free_storage_space" {
  alarm_name          = "${local.application_name}-rds-free-storage-space"
  comparison_operator = "LessThanOrEqualToThreshold"
  evaluation_periods  = "2"
  metric_name         = "FreeStorageSpace"
  namespace           = "AWS/RDS"
  period              = "300"
  statistic           = "Minimum"
  threshold           = "104857600" # 100 GB
  alarm_description   = "This metric monitors free storage space for the RDS instance"
  alarm_actions       = [aws_sns_topic.this.arn]
  ok_actions          = [aws_sns_topic.this.arn]
  dimensions = {
    DBInstanceIdentifier = aws_db_instance.iaps.identifier
  }
}
