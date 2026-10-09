output "staging_bucket_name" {
  description = "Name of the staging bucket, consumed by the web-ui root (var.forge_package_s3_bucket fallback) via terraform_remote_state."
  value       = module.staging_bucket.bucket.id
}

output "staging_bucket_kms_key_arn" {
  description = "ARN of the KMS key enforced on the staging bucket's objects -- clients must set this as the x-amz-server-side-encryption-aws-kms-key-id header on PutObject, or the bucket policy's explicit deny rejects the write."
  value       = aws_kms_key.staging_bucket.arn
}
