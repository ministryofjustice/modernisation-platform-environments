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
