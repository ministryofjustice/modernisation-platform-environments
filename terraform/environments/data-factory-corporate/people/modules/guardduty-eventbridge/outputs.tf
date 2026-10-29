# Returns the unique identifier of the GuardDuty Malware Protection plan.
output "rule_arn" {
  description = "ARN of the EventBridge rule."
  value       = aws_cloudwatch_event_rule.guardduty_quarantine.arn
}

output "scan_alerts_topic_arn" {
  description = "SNS topic to connect to an Amazon Q Developer in chat applications Slack channel for GuardDuty alerts."
  value       = aws_sns_topic.scan_alerts.arn
}

