output "target_bucket_name" {
  description = "Name of the temporary S3 bucket used as the DMS target."
  value       = aws_s3_bucket.dms_target.bucket
}

output "target_kms_key_arn" {
  description = "ARN of the KMS key used to encrypt the temporary DMS integration-test S3 target."
  value       = var.kms_key_arn
}

output "source_database_name" {
  description = "Database name exposed to the DMS source endpoint."
  value       = aws_db_instance.postgres.db_name
}

output "source_secret_arn" {
  description = "ARN of the RDS-managed Secrets Manager secret containing the PostgreSQL credentials."
  value       = aws_db_instance.postgres.master_user_secret[0].secret_arn
}

output "dms_source_secret_arn" {
  description = "ARN of the Secrets Manager secret used by DMS for source authentication."
  value       = aws_secretsmanager_secret.dms_source.arn
}

output "source_endpoint_address" {
  description = "DNS endpoint of the temporary PostgreSQL source."
  value       = aws_db_instance.postgres.address
}

output "source_port" {
  description = "Port of the temporary PostgreSQL source."
  value       = aws_db_instance.postgres.port
}

output "dms_client_security_group_id" {
  description = "Security group to attach to DMS so it is permitted to connect to the temporary PostgreSQL source."
  value       = aws_security_group.dms_client.id
}

output "bootstrap_lambda_function_name" {
  description = "Name of the Lambda function used to prepare the DMS integration test."
  value       = aws_lambda_function.bootstrap.function_name
}
