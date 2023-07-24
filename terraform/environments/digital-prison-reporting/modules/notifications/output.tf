output "sns_topic_arn" {
  value = aws_sns_topic.dpr-notification-topic.arn
}

output "target_name" {
  value = aws_sns_topic.dpr-notification-topic.arn
}