output "staging_bucket_name" {
  description = "Name of the staging bucket, consumed by the web-ui root via terraform_remote_state."
  value       = aws_s3_bucket.staging_bucket.id
}

output "staging_bucket_kms_key_arn" {
  description = "ARN of the KMS key used to encrypt staging bucket objects."
  value       = aws_kms_key.staging_bucket.arn
}
