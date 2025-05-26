output "rds_cluster_endpoint" {
  description = "The endpoint of the Aurora cluster"
  value       = module.aurora.cluster_endpoint
}

output "rds_cluster_port" {
  description = "The endpoint of the Aurora cluster"
  value       = module.aurora.cluster_port
}

output "rds_cluster_reader_endpoint" {
  description = "The read only endpoint of the Aurora cluster"
  value       = module.aurora.cluster_reader_endpoint
}

output "app_rotated_postgres_secret_arn" {
  description = "The ARN of the rotated postgres secret"
  value       = aws_secretsmanager_secret.user_admin_secret["postgres_rotated"].arn
}

output "rds_postgres_secret_arn" {
  description = "The ARN of the rotated postgres secret"
  value       = aws_secretsmanager_secret.user_admin_secret["postgres"].arn
}

output "rds_redshift_secret_arn" {
  description = "The ARN of the redshift_readonly secret"
  value       = aws_secretsmanager_secret.user_admin_secret["redshift_readonly"].arn
}

output "rds_quicksight_secret_arn" {
  description = "The ARN of the quicksight secret"
  value       = aws_secretsmanager_secret.user_admin_secret["ycs_team"].arn
}

output "rds_cluster_security_group_id" {
  description = "The ID of the Security Groups that is used to controll access to the RDS cluster."
  value       = aws_security_group.rds.id
}

output "cluster_arn" {
  description = "The ARN of the RDS Aurora cluster"
  value       = module.aurora.cluster_arn
}

output "cluster_id" {
  description = "The ID of the RDS Aurora cluster"
  value       = module.aurora.cluster_id
}