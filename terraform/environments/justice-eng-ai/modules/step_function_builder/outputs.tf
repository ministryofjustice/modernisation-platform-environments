output "arn" {
  description = "ARN of the created Step Functions state machine."
  value       = aws_sfn_state_machine.this.arn
}

output "name" {
  description = "Name of the created Step Functions state machine."
  value       = aws_sfn_state_machine.this.name
}

output "resume_arn" {
  description = "ARN of the companion state machine that resumes an execution paused at the wait_for_approval step; null when there is no such step."
  value       = try(aws_sfn_state_machine.resume[0].arn, null)
}

output "role_arn" {
  description = "ARN of the shared Step Functions execution role."
  value       = var.execution_role_arn
}