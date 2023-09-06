output "task_role" {
  value = aws_iam_role.task
}

output "service_role" {
  value = aws_iam_role.service
}

output "task_exec_role" {
  value = aws_iam_role.task_exec
}
