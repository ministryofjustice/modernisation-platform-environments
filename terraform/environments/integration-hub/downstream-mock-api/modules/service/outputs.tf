output "api_endpoint" {
  description = "HTTP API endpoint for the downstream mock API"
  value       = aws_apigatewayv2_api.service.api_endpoint
}

output "healthcheck_url" {
  description = "Health endpoint exposed through API Gateway"
  value       = "${aws_apigatewayv2_api.service.api_endpoint}${local.service_configuration.health_check_path}"
}

output "basic_auth_secret_name" {
  description = "Secrets Manager secret name for downstream Basic auth credentials"
  value       = module.downstream_basic_auth_secret.secret_name
}

output "ecr_repository_url" {
  description = "ECR repository URL for the downstream mock API container image"
  value       = aws_ecr_repository.application.repository_url
}

output "ecs_cluster_name" {
  description = "ECS cluster name for the downstream mock API service"
  value       = aws_ecs_cluster.service.name
}

output "ecs_service_name" {
  description = "ECS service name for the downstream mock API service"
  value       = aws_ecs_service.service.name
}

output "app_deploy_role_arn" {
  description = "IAM role ARN for the downstream mock API GitHub Actions deployment workflow"
  value       = aws_iam_role.app_deploy.arn
}
