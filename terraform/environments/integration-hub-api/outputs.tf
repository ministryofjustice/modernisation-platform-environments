output "transfer_ticket_api_endpoint" {
  description = "HTTP API endpoint for issuing managed file transfer upload tickets"
  value       = module.integration_hub_file_transfer_api.transfer_ticket_api_endpoint
}

output "transfer_ticket_api_docs_url" {
  description = "Protected Swagger UI for the managed file transfer API"
  value       = module.integration_hub_file_transfer_api.transfer_ticket_api_docs_url
}

output "transfer_ticket_openapi_url" {
  description = "Protected OpenAPI contract URL for the managed file transfer API"
  value       = module.integration_hub_file_transfer_api.transfer_ticket_openapi_url
}

output "transfer_ticket_api_docs_basic_auth_secret_name" {
  description = "Secrets Manager secret name for the Swagger UI basic auth credentials"
  value       = module.integration_hub_file_transfer_api.transfer_ticket_api_docs_basic_auth_secret_name
}

output "transfer_clients_table_name" {
  description = "DynamoDB table containing upload client configuration"
  value       = module.integration_hub_file_transfer_api.transfer_clients_table_name
}

output "auth_roles_table_name" {
  description = "DynamoDB table containing API authorisation roles"
  value       = module.integration_hub_file_transfer_api.auth_roles_table_name
}

output "auth_principals_table_name" {
  description = "DynamoDB table containing API authentication principals"
  value       = module.integration_hub_file_transfer_api.auth_principals_table_name
}

output "multipart_uploads_table_name" {
  description = "DynamoDB table containing multipart upload sessions"
  value       = module.integration_hub_file_transfer_api.multipart_uploads_table_name
}

output "lambda_function_names" {
  description = "Lambda function names for the app-owned deployment workflow"
  value       = module.integration_hub_file_transfer_api.lambda_function_names
}

output "app_deploy_role_arn" {
  description = "IAM role ARN for the companion repository GitHub Actions deployment workflow"
  value       = module.integration_hub_file_transfer_api.app_deploy_role_arn
}

output "observability_dashboard_name" {
  description = "CloudWatch dashboard name for API platform operational monitoring"
  value       = module.integration_hub_file_transfer_api.observability_dashboard_name
}

output "observability_high_priority_topic_arn" {
  description = "SNS topic ARN for high priority API platform alarms"
  value       = module.integration_hub_file_transfer_api.observability_high_priority_topic_arn
}

output "observability_low_priority_topic_arn" {
  description = "SNS topic ARN for low priority API platform alarms"
  value       = module.integration_hub_file_transfer_api.observability_low_priority_topic_arn
}

output "user_auth_secret_names" {
  description = "HTTPS upload credential secret names keyed by username"
  value       = module.integration_hub_file_transfer_api.user_auth_secret_names
}

output "system_auth_secret_names" {
  description = "Bearer token secret names keyed by system principal"
  value       = module.integration_hub_file_transfer_api.system_auth_secret_names
}
