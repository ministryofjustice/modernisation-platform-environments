output "cluster_ec2_security_group_id" {
  description = "Security group id of EC2s used for ECS cluster"
  value       = aws_security_group.cluster_ec2.id
}

output "current_task_definition" {
  description = "Displays task definition information and version being used"
  value       = data.aws_ecs_task_definition.task_definition
}

output "ecs_service" {
  description = "Displays task definition information and version being used"
  value       = aws_ecs_service.ecs_service
}

output "ecs_task_execution_role" {
  description = "Displays task definition role details"
  value       = aws_iam_role.ecs_task_execution_role
}

output "ecs_task_execution_policy" {
  description = "Displays task definition policy details"
  value       = data.aws_iam_policy_document.ecs_task_execution_role
}
