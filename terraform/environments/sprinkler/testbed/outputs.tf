output "rds_endpoint" {
  description = "RDS instance endpoint"
  value       = aws_db_instance.rds.endpoint
}

output "rds_address" {
  description = "RDS instance address (without port)"
  value       = aws_db_instance.rds.address
}

output "rds_password" {
  description = "RDS master password"
  value       = random_password.rds.result
  sensitive   = true
}
