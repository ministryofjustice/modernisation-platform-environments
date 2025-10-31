output "bucket_id" {
  value       = var.create_s3 ? join("", aws_s3_bucket.storage.*.id) : ""
  description = "Bucket Name (aka ID)"
}

output "bucket_arn" {
  value       = var.create_s3 ? join("", aws_s3_bucket.storage.*.arn) : ""
  description = "Bucket ARN"
}

output "sqs_arn" {
  value       = var.create_notification_queue ? join("", aws_sqs_queue.notification_queue.*.arn) : ""
  description = "SQS ARN"
}

output "sqs_url" {
  value       = var.create_notification_queue ? join("", aws_sqs_queue.notification_queue.*.url) : ""
  description = "SQS URL"
}

output "sqs_id" {
  value       = var.create_notification_queue ? join("", aws_sqs_queue.notification_queue.*.id) : ""
  description = "SQS ID"
}