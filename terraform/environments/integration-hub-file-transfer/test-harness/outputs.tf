output "destination_bucket_name" {
  description = "Destination bucket name for the pipeline smoke test"
  value       = module.destination.s3_bucket_id
}

output "destination_kms_key_arn" {
  description = "Destination encryption key ARN for the pipeline smoke test"
  value       = module.destination-encryption.key_arn
}