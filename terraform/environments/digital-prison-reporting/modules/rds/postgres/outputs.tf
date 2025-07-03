output "master_password" {
  description = "Master User Password"
  value       = try(data.aws_secretsmanager_secret_version.password.secret_string, "")
}

output "rds_host" {
  description = "RDS Host Endpoint"
  value       = try(aws_db_instance.default[0].address, "")
}

output "rds_port" {
  description = "RDS port"
  value       = try(aws_db_instance.default[0].port, "")
}