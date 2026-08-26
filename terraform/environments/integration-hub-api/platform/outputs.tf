output "benefit_checker_api_endpoint" {
  description = "Client-facing orchestration API endpoint"
  value       = try(aws_apigatewayv2_api.benefit_checker[0].api_endpoint, null)
}

output "benefit_orchestrator_function_name" {
  description = "Lambda function deployed by the application repository"
  value       = try(module.lambda_benefit_orchestrator[0].lambda_function_name, null)
}

output "request_authorizer_function_name" {
  description = "Request authorizer Lambda deployed by the application repository"
  value       = try(module.lambda_api_authorizer[0].lambda_function_name, null)
}

output "app_deploy_role_arn" {
  description = "GitHub Actions role for scoped application deployment"
  value       = try(aws_iam_role.app_deploy[0].arn, null)
}

output "user_auth_secret_names" {
  description = "Basic authentication secret names keyed by username"
  value       = { for username, secret in module.api_user_credentials_secret : username => secret.secret_name }
}

output "system_auth_secret_names" {
  description = "Bearer token secret names keyed by system principal"
  value       = { for principal, secret in module.api_system_bearer_token_secret : principal => secret.secret_name }
}
