output "bootstrap_lambda_function_name" {
  description = "Name of the Lambda function used to prepare the DMS integration test."
  value       = local.dms_core_enabled ? module.dms_test_harness[0].bootstrap_lambda_function_name : null
}