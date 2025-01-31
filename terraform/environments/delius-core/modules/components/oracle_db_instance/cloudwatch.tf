locals {
  instance_name = "${var.account_info.application_name}-${var.env_name}-${var.db_suffix}-${local.instance_name_index}"
  alarm_name    = "${local.instance_name}-instance-status-check-failed"
}

resource "aws_cloudwatch_log_group" "ec2_status_check_log_group" {
  name              = "/metrics/${var.env_name}/${local.alarm_name}"
  retention_in_days = 0 # Retain indefinitely
}

resource "aws_cloudwatch_event_rule" "ec2_status_check_failed_event" {
  name        = local.alarm_name
  description = "Rule to capture EC2 instance status check failures"
  event_pattern = jsonencode({
    "source" : ["aws.cloudwatch"],
    "detail-type" : ["CloudWatch Alarm State Change"],
    "detail" : {
      "state" : ["ALARM"],
      "alarmName" : ["${local.alarm_name}"]
    }
  })
}

resource "aws_cloudwatch_event_target" "ec2_status_check_failed_target" {
  rule      = aws_cloudwatch_event_rule.ec2_status_check_failed_event.name
  arn       = aws_cloudwatch_log_group.ec2_status_check_log_group.arn
  target_id = local.alarm_name
}

resource "aws_cloudwatch_log_resource_policy" "log_group_policy" {
  policy_name = local.alarm_name
  policy_document = jsonencode({
    Version = "2012-10-17",
    Statement : [{
      Action = "logs:PutLogEvents",
      Effect = "Allow",
      Principal = {
        Service = "events.amazonaws.com"
      },
      Resource = aws_cloudwatch_log_group.ec2_status_check_log_group.arn
    }]
  })
}
