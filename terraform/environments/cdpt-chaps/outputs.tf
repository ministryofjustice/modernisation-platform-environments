output "chaps_task_definition" {
  value = aws_ecs_task_definition.chaps_task_definition.arn
}

output "chapsdotnet_task_definition" {
  value = aws_ecs_task_definition.chapsdotnet_task[0].arn
}
