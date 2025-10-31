output "secret" {
  description = "Generated secret"
  value       = var.generate_random ? random_password.random_string[0].result : ""
  sensitive   = true
}

output "secret_arn" {
  description = "The ARN of the secret"
  value       = aws_secretsmanager_secret.secret.arn
}

output "secret_id" {
  description = "Generated secret"
  value       = aws_secretsmanager_secret.secret.id
  sensitive   = true
}