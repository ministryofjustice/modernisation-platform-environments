output "chaps_task_definition" {
  value = data.aws_ecs_task_definition.chaps_task_definition
}

output "chapsdotnet_task_definition" {
  value = data.aws_ecs_task_definition.chapsdotnet_task_definition
}
