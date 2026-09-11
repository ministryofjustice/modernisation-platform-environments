# Returns the unique identifier of the GuardDuty Malware Protection plan.
output "rule_arn" {
  description = "ARN of the EventBridge rule."
  value       = aws_cloudwatch_event_rule.guardduty_quarantine.arn
}

