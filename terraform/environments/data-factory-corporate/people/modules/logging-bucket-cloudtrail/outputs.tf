output "log_bucket_name" {
  description = "The name of the central log bucket."
  value       = module.log_bucket.bucket.id
}

output "cloudtrail_arn" {
  description = "The ARN of the CloudTrail."
  value       = aws_cloudtrail.sherlock.arn
}
