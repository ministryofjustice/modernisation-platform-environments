output "bootstrap_lambda_function_name" {
  description = "Name of the Lambda function used to prepare the DMS integration test."
  value       = local.dms_core_enabled ? module.dms_test_harness[0].bootstrap_lambda_function_name : null
}

output "runtime_control_lambda_function_name" {
  description = "Name of the Lambda function that synchronises credentials, validates the source endpoint and starts or resumes the DMS task."
  value       = local.dms_core_enabled ? aws_lambda_function.runtime_control[0].function_name : null
}
