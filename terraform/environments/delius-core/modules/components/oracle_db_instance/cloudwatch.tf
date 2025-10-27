locals {
  instance_name = "${var.account_info.application_name}-${var.env_name}-${var.db_suffix}-${local.instance_name_index}"
  alarm_name    = "${local.instance_name}-instance-unavailable"
}

resource "aws_cloudwatch_metric_alarm" "status_check_failed_alarm" {
  count               = var.enable_cloudwatch_alarms ? 1 : 0
  alarm_name          = local.alarm_name
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = 1
  metric_name         = "StatusCheckFailed"
  namespace           = "AWS/EC2"
  period              = 60
  statistic           = "Average"
  threshold           = 1
  actions_enabled     = true
  alarm_description   = "Alarm when the EC2 instance has failed the status check, or lacks 'sufficient data'"
  dimensions = {
    InstanceId = module.instance.aws_instance.id
  }
  treat_missing_data = "breaching"
}

resource "aws_cloudwatch_log_group" "ec2_status_check_log_group" {
  #checkov:skip=CKV_AWS_158 "ignore"
  count             = var.enable_cloudwatch_alarms ? 1 : 0
  name              = "/metrics/${var.env_name}/${local.alarm_name}"
  retention_in_days = 0 # Retain indefinitely
}

resource "aws_cloudwatch_event_rule" "ec2_status_check_failed_event" {
  count       = var.enable_cloudwatch_alarms ? 1 : 0
  name        = local.alarm_name
  description = "Rule to capture EC2 instance status check failures"
  event_pattern = jsonencode({
    "source" : ["aws.cloudwatch"],
    "detail-type" : ["CloudWatch Alarm State Change"],
    "detail" : {
      "state" : {
        "value" : ["ALARM"]
      }
      "alarmName" : [local.alarm_name]
    }
  })
}

resource "aws_cloudwatch_event_target" "ec2_status_check_failed_target" {
  count     = var.enable_cloudwatch_alarms ? 1 : 0
  rule      = aws_cloudwatch_event_rule.ec2_status_check_failed_event[0].name
  arn       = aws_cloudwatch_log_group.ec2_status_check_log_group[0].arn
  target_id = local.alarm_name
}
