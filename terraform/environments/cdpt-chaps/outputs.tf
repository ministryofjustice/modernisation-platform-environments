output "chaps_task_definition" {
  value = aws_ecs_task_definition.chaps_task_definition.arn
}

output "chapsdotnet_task_definition" {
  value       = length(aws_ecs_task_definition.chapsdotnet_task) > 0 ? aws_ecs_task_definition.chapsdotnet_task[0].arn : null
  description = "The ARN of the chapsdotnet task definition, if it exists."
}

output "debug_client_id" {
  value = local.application_data.accounts[local.environment].client_id
}

output "chaps_instances_details" {
  description = "Details of the fetched chaps instances"
  value = data.aws_instances.chaps_instances
}

output "chaps_instances_ips" {
  value = data.aws_instances.chaps_instances[*].private_ips
}