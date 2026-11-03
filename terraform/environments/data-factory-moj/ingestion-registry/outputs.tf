output "ingestion_registry_table_name" {
  description = "Name of the shared Ingestion Registry table, or null outside development."
  value       = one(module.ingestion_registry[*].table_name)
}

output "ingestion_registry_table_arn" {
  description = "ARN of the shared Ingestion Registry table, or null outside development."
  value       = one(module.ingestion_registry[*].table_arn)
}

output "ingestion_registry_kms_key_arn" {
  description = "ARN of the Ingestion Registry encryption key, or null outside development."
  value       = one(aws_kms_key.ingestion_registry[*].arn)
}

output "ingestion_configuration_bucket_name" {
  description = "Published configuration bucket name, or null outside development."
  value       = try(aws_s3_bucket.ingestion_configuration["documents"].id, null)
}

output "ingestion_configuration_bucket_arn" {
  description = "Published configuration bucket ARN, or null outside development."
  value       = try(aws_s3_bucket.ingestion_configuration["documents"].arn, null)
}

output "ingestion_configuration_kms_key_arn" {
  description = "Published configuration encryption key ARN, or null outside development."
  value       = one(aws_kms_key.ingestion_configuration[*].arn)
}

output "ingestion_configuration_access_log_bucket_name" {
  description = "Configuration access-log bucket name, or null outside development."
  value       = try(aws_s3_bucket.ingestion_configuration["access_logs"].id, null)
}
