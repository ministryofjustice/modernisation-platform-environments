output "file_uploads_bucket_arn" {
  description = "ARN of the file uploads bucket"
  value       = module.file_uploads_bucket.bucket.arn
}

output "lambda_role_arn" {
  description = "ARN of the Lambda execution role"
  value       = module.process_uploads_lambda.lambda_role_arn
}
