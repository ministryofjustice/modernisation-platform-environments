output "clean_bucket_events_topic_arn" {
  description = "SNS topic ARN that receives clean bucket object-created notifications"
  value       = module.sns_clean_bucket_events.topic_arn
}

output "clean_file_download_notifications_topic_arn" {
  description = "SNS topic ARN that receives Slack-ready clean file download notifications"
  value       = module.sns_clean_file_download_notifications.topic_arn
}

output "clean_file_notifications_queue_arn" {
  description = "SQS queue ARN consumed by the clean file presigned URL notifier Lambda"
  value       = module.sqs_clean_file_notifications.queue_arn
}
