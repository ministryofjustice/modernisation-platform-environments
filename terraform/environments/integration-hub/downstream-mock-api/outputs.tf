output "api_endpoint" {
  description = "HTTP API endpoint for the downstream mock API"
  value       = try(module.service[0].api_endpoint, null)
}

output "healthcheck_url" {
  description = "Health endpoint exposed through API Gateway"
  value       = try(module.service[0].healthcheck_url, null)
}

output "basic_auth_secret_name" {
  description = "Secrets Manager secret name for downstream Basic auth credentials"
  value       = try(module.service[0].basic_auth_secret_name, null)
}

output "ecr_repository_url" {
  description = "ECR repository URL for the downstream mock API container image"
  value       = try(module.service[0].ecr_repository_url, null)
}

output "ecs_cluster_name" {
  description = "ECS cluster name for the downstream mock API service"
  value       = try(module.service[0].ecs_cluster_name, null)
}

output "ecs_service_name" {
  description = "ECS service name for the downstream mock API service"
  value       = try(module.service[0].ecs_service_name, null)
}

output "app_deploy_role_arn" {
  description = "IAM role ARN for the downstream mock API GitHub Actions deployment workflow"
  value       = try(module.service[0].app_deploy_role_arn, null)
}
