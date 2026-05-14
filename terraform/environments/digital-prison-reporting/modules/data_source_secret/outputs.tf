output "secret_arn" {
  value = aws_secretsmanager_secret.this.arn
}

output "secret_name" {
  value = aws_secretsmanager_secret.this.name
}

output "secret_version_id" {
  value = aws_secretsmanager_secret_version.this.version_id
}
