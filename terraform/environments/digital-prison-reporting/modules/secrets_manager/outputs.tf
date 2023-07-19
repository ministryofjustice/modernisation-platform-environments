output "secret" {
  description = "Generated secret"
  value       = var.generate_random ? random_password.random_string[0].result : ""
  sensitive   = true
}

output "secret_arn" {
  description = "The ARN of the secret"
  value       = aws_secretsmanager_secret.secret.arn
}

output "version_id" {
  description = "The unique identifier of the version of the secret."
  value       = aws_secretsmanager_secret_version.secret_val.version_id
}