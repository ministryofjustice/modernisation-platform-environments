output "staging_bucket_name" {
  description = "Name of the staging bucket, consumed by the web-ui root via terraform_remote_state."
  value       = aws_s3_bucket.staging_bucket.id
}

output "staging_bucket_kms_key_arn" {
  description = "ARN of the KMS key used to encrypt staging bucket objects."
  value       = aws_kms_key.staging_bucket.arn
}

output "build_details_table_name" {
  description = "Name of the build details DynamoDB table, consumed by the web-ui root via terraform_remote_state."
  value       = aws_dynamodb_table.build_review.name
}

output "build_counter_sys_key" {
  description = "SysKey of the counter item in the build details table."
  value       = local.build_counter_sys_key
}

output "build_counter_attribute" {
  description = "Attribute of the counter item that holds the latest SysKey."
  value       = local.build_counter_attribute
}
