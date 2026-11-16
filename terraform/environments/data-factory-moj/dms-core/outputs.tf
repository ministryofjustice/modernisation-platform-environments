output "bootstrap_lambda_function_name" {
  description = "Name of the Lambda function used to prepare the DMS integration test."
  value       = local.dms_core_enabled ? module.dms_test_harness[0].bootstrap_lambda_function_name : null
}

output "postgres_seed_lambda_function_name" {
  description = "Name of the Lambda function used to reset, seed, mutate and read the PostgreSQL integration-test source."
  value       = local.dms_core_enabled ? module.dms_test_harness[0].seed_lambda_function_name : null
}

output "runtime_control_lambda_function_name" {
  description = "Name of the Lambda function that synchronises credentials, validates the source endpoint and starts or resumes the DMS task."
  value       = local.dms_core_enabled ? aws_lambda_function.runtime_control[0].function_name : null
}

output "oracle_seed_lambda_function_name" {
  description = "Name of the Lambda function used to reset, seed, mutate and read the Oracle integration-test source."
  value       = local.dms_core_enabled ? module.oracle_test_harness[0].seed_lambda_function_name : null
}

output "oracle_rds_instance_identifier" {
  description = "Identifier of the temporary Oracle RDS integration-test source."
  value       = local.dms_core_enabled ? module.oracle_test_harness[0].rds_instance_identifier : null
}

output "oracle_replication_instance_arn" {
  description = "ARN of the DMS replication instance used for the Oracle integration test."
  value       = local.dms_core_enabled ? module.oracle_source_ingestion[0].dms_replication_instance_arn : null
}

output "oracle_source_endpoint_arn" {
  description = "ARN of the Oracle DMS source endpoint."
  value       = local.dms_core_enabled ? module.oracle_source_ingestion[0].dms_source_endpoint_arn : null
}

output "oracle_replication_task_arn" {
  description = "ARN of the Oracle Full Load and CDC replication task."
  value       = local.dms_core_enabled ? module.oracle_source_ingestion[0].replication_tasks["full_load_and_cdc"].arn : null
}

output "oracle_target_bucket_name" {
  description = "Name of the S3 bucket used by the Oracle DMS integration test."
  value       = local.dms_core_enabled ? module.oracle_test_harness[0].target_bucket_name : null
}

output "oracle_rotation_lambda_function_name" {
  description = "Name of the Lambda function that rotates the Oracle DMS source credential."
  value       = local.dms_core_enabled ? module.oracle_test_harness[0].rotation_lambda_function_name : null
}

output "oracle_runtime_control_lambda_function_name" {
  description = "Name of the Lambda function that validates the Oracle DMS endpoint after credential rotation."
  value       = local.dms_core_enabled ? aws_lambda_function.oracle_runtime_control[0].function_name : null
}

output "oracle_preflight_failure_queue_url" {
  description = "URL of the queue containing Oracle DMS endpoint preflight events that exhausted their retries."
  value       = local.dms_core_enabled ? aws_sqs_queue.oracle_preflight_failures[0].url : null
}
