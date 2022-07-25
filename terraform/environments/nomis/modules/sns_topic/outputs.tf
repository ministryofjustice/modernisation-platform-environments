output "sns_topic_policy" {
  value = aws_iam_policy.policy
}

output "topic_name" {
  description = "Name for the topic"
  value       = aws_sns_topic.sns_topic.name
}

output "topic_arn" {
  description = "ARN for the topic"
  value       = aws_sns_topic.sns_topic.arn
}
