################################################################################
# DB Parameter Group
################################################################################
output "db_parameter_group_arn" {
  description = "The ARN of the DB parameter group created"
  value       = try(aws_db_parameter_group.parameter_group[0].arn, null)
}

output "parameter_group_id" {
  value       = try(aws_db_parameter_group.parameter_group[0].id, null)
  description = "The ID of the DB parameter group created"
}

output "parameter_group_name" {
  value       = try(aws_db_parameter_group.parameter_group[0].name, null)
  description = "The name of the parameter group created"
}