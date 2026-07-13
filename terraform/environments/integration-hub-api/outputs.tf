output "transfer_ticket_api_endpoint" {
  description = "HTTP API endpoint for issuing managed file transfer upload tickets"
  value       = aws_apigatewayv2_api.upload_ticket.api_endpoint
}

output "transfer_ticket_api_docs_url" {
  description = "Protected Swagger UI for the managed file transfer API"
  value       = "${aws_apigatewayv2_api.upload_ticket.api_endpoint}/docs"
}

output "transfer_ticket_openapi_url" {
  description = "Protected OpenAPI contract URL for the managed file transfer API"
  value       = "${aws_apigatewayv2_api.upload_ticket.api_endpoint}/openapi.yaml"
}

output "transfer_ticket_api_docs_basic_auth_secret_name" {
  description = "Secrets Manager secret name for the Swagger UI basic auth credentials"
  value       = module.api_docs_basic_auth_secret.secret_name
}

output "transfer_clients_table_name" {
  description = "DynamoDB table containing upload client configuration"
  value       = module.dynamodb_transfer_clients.dynamodb_table_id
}

output "auth_roles_table_name" {
  description = "DynamoDB table containing API authorisation roles"
  value       = module.dynamodb_auth_roles.dynamodb_table_id
}

output "auth_principals_table_name" {
  description = "DynamoDB table containing API authentication principals"
  value       = module.dynamodb_auth_principals.dynamodb_table_id
}

output "multipart_uploads_table_name" {
  description = "DynamoDB table containing multipart upload sessions"
  value       = module.dynamodb_multipart_uploads.dynamodb_table_id
}

output "lambda_function_names" {
  description = "Lambda function names for the app-owned deployment workflow"
  value = {
    api_docs      = module.lambda_api_docs.lambda_function_name
    authorizer    = module.lambda_api_authorizer.lambda_function_name
    upload_ticket = module.lambda_upload_ticket.lambda_function_name
  }
}

output "app_deploy_role_arn" {
  description = "IAM role ARN for the companion repository GitHub Actions deployment workflow"
  value       = aws_iam_role.app_deploy.arn
}

output "user_auth_secret_names" {
  description = "HTTPS upload credential secret names keyed by username"
  value = {
    for username, secret in module.api_user_credentials_secret : username => secret.secret_name
  }
}

output "system_auth_secret_names" {
  description = "Bearer token secret names keyed by system principal"
  value = {
    for principal, secret in module.api_system_bearer_token_secret : principal => secret.secret_name
  }
}
