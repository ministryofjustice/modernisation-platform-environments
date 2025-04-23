
output "ecs_service_external_sg_id" {
  description = "The ID of the securiy group that controlls access to External ECS microservices (i.e the Gateway)."
  value       = aws_security_group.common_ecs_service_external.id
}

output "ecs_service_internal_sg_id" {
  description = "The ID of the securiy group that controlls access to Internal ECS microservices (i.e the Gateway)."
  value       = aws_security_group.common_ecs_service_internal.id
}

output "ecs_cluster_arn" {
  description = "The ARN of the ECS cluster"
  value       = module.ecs_cluster.arn
}

output "ecs_task_role_name" {
  description = "The name of the ECS task role"
  value       = aws_iam_role.ecs_task_role.name
}

output "ecs_task_role_arn" {
  description = "The ARN of the ECS task role"
  value       = aws_iam_role.ecs_task_role.arn
}

output "ecs_task_execution_role_arn" {
  description = "The ARN of the ECS task execution role"
  value       = aws_iam_role.ecs_task_execution_role.arn
}
