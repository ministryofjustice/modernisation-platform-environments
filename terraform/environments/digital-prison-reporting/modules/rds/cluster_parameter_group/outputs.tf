################################################################################
# Cluster Parameter Group
################################################################################

output "db_cluster_parameter_group_arn" {
  description = "The ARN of the DB cluster parameter group created"
  value       = try(aws_rds_cluster_parameter_group.this[0].arn, null)
}

output "db_cluster_parameter_group_id" {
  description = "The ID of the DB cluster parameter group created"
  value       = try(aws_rds_cluster_parameter_group.this[0].id, null)
}

output "db_cluster_parameter_group_name" {
  description = "The Name of the DB cluster parameter group created"
  value       = try(aws_rds_cluster_parameter_group.this[0].name, null)
}