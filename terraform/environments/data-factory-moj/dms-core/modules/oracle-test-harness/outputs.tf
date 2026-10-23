output "target_bucket_name" {
  description = "Name of the temporary S3 bucket used as the Oracle DMS target."
  value       = aws_s3_bucket.dms_target.bucket
}

output "target_kms_key_arn" {
  description = "ARN of the KMS key used to encrypt the Oracle integration-test S3 target."
  value       = var.kms_key_arn
}

output "source_database_name" {
  description = "Oracle database or service name exposed to the DMS source endpoint."
  value       = aws_db_instance.oracle.db_name
}

output "dms_source_secret_arn" {
  description = "ARN of the Secrets Manager secret used by DMS for Oracle source authentication."
  value       = aws_secretsmanager_secret.dms_source.arn
}

output "source_endpoint_address" {
  description = "DNS endpoint of the temporary Oracle source."
  value       = aws_db_instance.oracle.address
}

output "source_port" {
  description = "Port exposed by the temporary Oracle source."
  value       = aws_db_instance.oracle.port
}

output "dms_client_security_group_id" {
  description = "Security group attached to DMS to permit access to the temporary Oracle source."
  value       = aws_security_group.dms_client.id
}

output "seed_lambda_function_name" {
  description = "Name of the Lambda function used to reset, seed, mutate and read the Oracle integration-test source."
  value       = aws_lambda_function.seed.function_name
}

output "rds_instance_identifier" {
  description = "Identifier of the temporary Oracle RDS instance."
  value       = aws_db_instance.oracle.identifier
}

output "rotation_lambda_function_name" {
  description = "Name of the Lambda function that rotates the Oracle DMS source credential."
  value       = aws_lambda_function.rotation.function_name
}

output "dms_source_secret_id" {
  description = "ID of the Secrets Manager secret used for Oracle DMS authentication."
  value       = aws_secretsmanager_secret.dms_source.id
}

output "dms_source_secret_name" {
  description = "Name of the Secrets Manager secret used for Oracle DMS authentication."
  value       = aws_secretsmanager_secret.dms_source.name
}

output "rotation_lambda_function_arn" {
  description = "ARN of the Lambda function that rotates the Oracle DMS source credential."
  value       = aws_lambda_function.rotation.arn
}
