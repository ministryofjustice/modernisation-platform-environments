output "rule_arn" {
  value = aws_cloudwatch_event_rule.glue-jobs-status-change-rule.arn
}

output "sns_topic_arn" {
  value = aws_sns_topic.glue-jobs-notification-topic.arn
}