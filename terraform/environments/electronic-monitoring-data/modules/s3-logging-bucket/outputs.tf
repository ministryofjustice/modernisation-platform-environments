output "logging_bucket_id" {
  description = "The ID of the logging S3 bucket"
  value       = aws_s3_bucket.logging_bucket.id
}

output "logging_bucket_arn" {
  description = "The ARN of the logging S3 bucket"
  value       = aws_s3_bucket.logging_bucket.arn
}
