output "access_log_source_arns" {
  description = "Bucket ARNs allowed to write to the shared access logging destination."
  value = [
    module.file_uploads_bucket.bucket.arn,
    module.processed_file_uploads_bucket.bucket.arn
  ]
}

output "file_uploads_bucket_arn" {
  description = "ARN of the file uploads bucket"
  value       = module.file_uploads_bucket.bucket.arn
}

output "lambda_role_arn" {
  description = "ARN of the Lambda execution role"
  value       = module.process_uploads_lambda.lambda_role_arn
}
