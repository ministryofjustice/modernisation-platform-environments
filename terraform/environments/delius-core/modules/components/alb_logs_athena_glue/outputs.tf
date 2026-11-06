output "bucket_id" {
  value       = module.s3_bucket.bucket.id
  description = "The ID of the S3 bucket for ALB logs"
}