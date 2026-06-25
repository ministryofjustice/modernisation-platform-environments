output "dynamodb_idempotency" {
  description = "The full output of the DynamoDB idempotency module."
  value       = module.dynamodb_idempotency
}

output "sns_clean_bucket_events" {
  description = "The full output of the SNS clean bucket events module."
  value       = module.sns_clean_bucket_events
}

output "clean_bucket_events" {
  description = "The full output of the clean bucket notification resource."
  value       = aws_s3_bucket_notification.clean_bucket_events
}

output "sqs_clean_file_notifications" {
  description = "The full output of the SQS clean file notifications module."
  value       = module.sqs_clean_file_notifications
}

output "sns_clean_file_download_notifications" {
  description = "The full output of the SNS clean file download notifications module."
  value       = module.sns_clean_file_download_notifications
}

output "lambda_clean_file_presigned_url_notifier" {
  description = "The full output of the Lambda clean file presigned URL notifier module."
  value       = module.lambda_clean_file_presigned_url_notifier
}

output "chatbot_clean_file_download_notifications" {
  description = "The full output of the Chatbot clean file download notifications module."
  value       = module.chatbot_clean_file_download_notifications
}