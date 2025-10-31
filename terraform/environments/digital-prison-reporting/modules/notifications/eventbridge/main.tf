resource "aws_cloudwatch_event_rule" "event_rule" {
  name = var.rule_name

  event_pattern = var.event_pattern

  state = var.state

  tags = merge(
    var.tags,
    {
      Resource_Type = "EventBridge Rule"
    }
  )
}

resource "aws_cloudwatch_event_target" "event_target" {
  rule      = aws_cloudwatch_event_rule.event_rule.name
  target_id = var.event_target_name
  arn       = var.sns_topic_arn
}