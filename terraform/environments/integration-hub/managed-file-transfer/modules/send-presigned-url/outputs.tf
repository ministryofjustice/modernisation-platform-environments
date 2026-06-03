output "clean_bucket_events_topic_arn" {
  description = "SNS topic ARN that receives clean bucket object-created notifications"
  value       = aws_sns_topic.clean_bucket_events.arn
}

output "clean_file_download_notifications_topic_arn" {
  description = "SNS topic ARN that receives Slack-ready clean file download notifications"
  value       = aws_sns_topic.clean_file_download_notifications.arn
}

output "clean_file_notifications_queue_arn" {
  description = "SQS queue ARN consumed by the clean file presigned URL notifier Lambda"
  value       = module.sqs_clean_file_notifications.queue_arn
}
