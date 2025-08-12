# S3 Bucket outputs
output "s3_buckets" {
  description = "Map of S3 buckets created"
  value       = module.s3_bucket
}

output "s3_bucket_iam_policies" {
  description = "Map of IAM policies created for S3 bucket access"
  value       = aws_iam_policy.s3_bucket_access
}
