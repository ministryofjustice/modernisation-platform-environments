output "rds_cluster_endpoint" {
  description = "The endpoint of the Aurora cluster"
  value       = module.aurora.cluster_endpoint
}

output "app_rotated_postgres_secret_arn" {
  description = "The ARN of the rotated postgres secret"
  value       = aws_secretsmanager_secret.user_admin_secret["postgres_rotated"].arn
}
