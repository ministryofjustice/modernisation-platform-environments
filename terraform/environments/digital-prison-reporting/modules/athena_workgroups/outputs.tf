output "name" {
  description = "The workgroup's name, or null if it isn't set up"
  value       = one(aws_athena_workgroup.main[*].name)
}

output "arn" {
  description = "The workgroup's ARN, or null if it isn't set up"
  value       = one(aws_athena_workgroup.main[*].arn)
}
