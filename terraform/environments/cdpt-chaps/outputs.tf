output "chaps_task_definition" {
  value = aws_ecs_task_definition.chaps_task_definition.arn
}

output "chapsdotnet_task_definition" {
  value = aws_ecs_task_definition.chapsdotnet_task.arn
}

output "debug_client_id" {
  value = local.application_data.accounts[local.environment].client_id
}
