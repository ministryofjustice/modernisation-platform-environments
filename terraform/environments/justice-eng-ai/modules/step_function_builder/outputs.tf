output "arn" {
  description = "ARN of the created Step Functions state machine."
  value       = aws_sfn_state_machine.this.arn
}

output "name" {
  description = "Name of the created Step Functions state machine."
  value       = aws_sfn_state_machine.this.name
}

output "role_arn" {
  description = "ARN of the shared Step Functions execution role."
  value       = var.execution_role_arn
}