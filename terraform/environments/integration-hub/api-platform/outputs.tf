output "transfer_ticket_api_endpoint" {
  description = "HTTP API endpoint for issuing managed file transfer upload tickets"
  value       = aws_apigatewayv2_api.upload_ticket.api_endpoint
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
