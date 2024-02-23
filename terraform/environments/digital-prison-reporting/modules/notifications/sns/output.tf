output "sns_topic_arn" {
  value = aws_sns_topic.dpr-notification-topic.arn
}

output "sns_topic" {
  value = var.sns_topic_name
}