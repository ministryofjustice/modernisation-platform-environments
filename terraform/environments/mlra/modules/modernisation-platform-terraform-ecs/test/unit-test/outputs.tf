output "task_definition_arn" {
  description = "Displays task definition cluster arn"
  value       = module.ecs.current_task_definition.arn
}

output "ecs_cluster_arn" {
  description = "Displays ECS cluster arn"
  value       = module.ecs.ecs_service.cluster
}

output "ecs_task_execution_role_id" {
  description = "Displays task definition IAM role ID"
  value       = module.ecs.ecs_task_execution_role.id
}
