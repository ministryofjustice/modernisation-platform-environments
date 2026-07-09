output "clean_file_client_notification_topic_arn" {
  description = "SNS topic ARN for client-facing clean file ready notifications."
  value       = module.proof_of_concept_notification.sns_clean_file_client_notifications.topic_arn
}

output "products_poc_clean_file_notification_test_queue_url" {
  description = "Development-only SQS queue URL subscribed to products-poc clean file ready notifications."
  value       = local.environment == "development" ? module.sqs_products_poc_clean_file_ready_notifications[0].queue_url : null
}

output "products_poc_destination_presign_api_url" {
  description = "Development-only mock consumer API URL that returns presigned destination upload targets for products-poc."
  value       = local.environment == "development" ? aws_lambda_function_url.products_poc_destination_presign_api[0].function_url : null
}
