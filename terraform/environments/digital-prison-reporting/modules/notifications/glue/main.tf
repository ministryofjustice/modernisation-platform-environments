resource "aws_cloudwatch_event_rule" "glue-jobs-status-change-rule" {
  name = var.glue_rule_name

  event_pattern = <<PATTERN
{
  "source": ["aws.glue"],
  "detail-type": ["Glue Job State Change"],
  "detail": {
    "state": ["STOPPED", "FAILED", "TIMEOUT"]
  }
}
PATTERN

  tags = merge(
    var.tags,
    {
      Resource_Type = "EventBridge Rule"
    }
  )
}

resource "aws_cloudwatch_event_target" "glue-jobs-notification-target" {
  rule      = aws_cloudwatch_event_rule.glue-jobs-status-change-rule.name
  target_id = var.glue_rule_target_name
  arn       = var.aws_sns_topic_arn
}