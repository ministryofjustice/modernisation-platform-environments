output "bucket_id" {
  value       = var.create_s3 ? join("", aws_s3_bucket.application_tf_state.*.id) : ""
  description = "Bucket Name (aka ID)"
}

output "bucket_arn" {
  value       = var.create_s3 ? join("", aws_s3_bucket.application_tf_state.*.arn) : ""
  description = "Bucket ARN"
}