output "arn" {
  value = aws_sfn_state_machine.this.arn
}

output "id" {
  value = replace(replace(replace(replace(aws_sfn_state_machine.this.id, ":", "-"), "/", "-"), "_", "-"), "arn", "")
}

output "role_arn" {
  value = aws_iam_role.step_function_role.arn
}
