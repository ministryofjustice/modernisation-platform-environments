#### GuardDuty alerting – send all findings to the cw_alerts SNS topic
#### (Lambda subscribed to cw_alerts will forward to Slack)

resource "aws_cloudwatch_event_rule" "guardduty" {
  name = "${local.application_name}-${local.environment}-guardduty-findings"

  event_pattern = jsonencode({
    "source"      : ["aws.guardduty"],
    "detail-type" : ["GuardDuty Finding"]
  })
}

resource "aws_cloudwatch_event_target" "guardduty_to_cw_alerts" {
  rule      = aws_cloudwatch_event_rule.guardduty.name
  target_id = "send-guardduty-findings-to-cw-alerts"
  arn       = aws_sns_topic.cw_alerts.arn
}
