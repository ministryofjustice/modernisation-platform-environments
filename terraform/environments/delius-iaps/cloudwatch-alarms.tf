# Dashboard

## Alarms
resource "aws_cloudwatch_metric_alarm" "iapsv2_asg_CPUUtilization_warning" {
  alarm_name                = "${local.environment}-iapsv2-asg-CPUUtilization-warning"
  comparison_operator       = "GreaterThanOrEqualToThreshold"
  evaluation_periods        = "2"
  metric_name               = "CPUUtilization"
  namespace                 = "AWS/EC2"
  period                    = "120"
  statistic                 = "Average"
  threshold                 = "60"
  alarm_actions             = []
  ok_actions                = []
  insufficient_data_actions = []
  alarm_description         = "ec2 cpu utilization for the IAPS ASG is greater than 60%"
  tags                      = local.tags

  dimensions = {
    AutoScalingGroupName = module.ec2_iaps_server.autoscaling_group_name
  }
}

resource "aws_cloudwatch_metric_alarm" "iapsv2_asg_CPUUtilization_critical" {
  alarm_name                = "${local.environment}-iapsv2-asg-CPUUtilization-critical"
  comparison_operator       = "GreaterThanOrEqualToThreshold"
  evaluation_periods        = "2"
  metric_name               = "CPUUtilization"
  namespace                 = "AWS/EC2"
  period                    = "120"
  statistic                 = "Average"
  threshold                 = "80"
  alarm_actions             = []
  ok_actions                = []
  insufficient_data_actions = []
  alarm_description         = "ec2 cpu utilization for the IAPS ASG is greater than 80%"
  tags                      = local.tags

  dimensions = {
    AutoScalingGroupName = module.ec2_iaps_server.autoscaling_group_name
  }
}

resource "aws_cloudwatch_metric_alarm" "iapsv2_asg_StatusCheckFailed" {
  alarm_name                = "${local.environment}-iapsv2-asg-StatusCheckFailed-critical"
  comparison_operator       = "GreaterThanOrEqualToThreshold"
  evaluation_periods        = "1"
  metric_name               = "StatusCheckFailed"
  namespace                 = "AWS/EC2"
  period                    = "300"
  statistic                 = "Average"
  threshold                 = "1"
  alarm_actions             = []
  ok_actions                = []
  insufficient_data_actions = []
  alarm_description         = "ec2 StatusCheckFailed for one or more instances in the IAPS v2 ASG"
  tags                      = local.tags

  dimensions = {
    AutoScalingGroupName = module.ec2_iaps_server.autoscaling_group_name
  }
}

resource "aws_cloudwatch_metric_alarm" "iapsv2_asg_GroupInServiceInstances" {
  alarm_name                = "${local.environment}-iapsv2-asg-GroupInServiceInstances-critical"
  comparison_operator       = "LessThanThreshold"
  evaluation_periods        = "1"
  metric_name               = "GroupInServiceInstances"
  namespace                 = "AWS/AutoScaling"
  period                    = "300"
  statistic                 = "Average"
  threshold                 = "1"
  alarm_actions             = []
  ok_actions                = []
  insufficient_data_actions = []
  alarm_description         = "There is less than 1 instance InService for ec2 IAPS ASG"
  tags                      = local.tags

  dimensions = {
    AutoScalingGroupName = module.ec2_iaps_server.autoscaling_group_name
  }
}
