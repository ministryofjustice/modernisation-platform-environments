output "secret_arn" {
  value = aws_secretsmanager_secret.this.arn
}

output "secret_id" {
  value = aws_secretsmanager_secret.this.id
}

output "secret_name" {
  value = aws_secretsmanager_secret.this.name
}

output "secret_version_id" {
  value = aws_secretsmanager_secret_version.this.version_id
}

output "secret_contents_endpoint" {
  description = "The endpoint extracted from the secret string"
  value       = jsondecode(aws_secretsmanager_secret_version.this.secret_string)["endpoint"]
  sensitive   = true
}

output "secret_contents_port" {
  description = "The port extracted from the secret string"
  value       = jsondecode(aws_secretsmanager_secret_version.this.secret_string)["port"]
  sensitive   = true
}

output "secret_contents_db_name" {
  description = "The db_name extracted from the secret string"
  value       = jsondecode(aws_secretsmanager_secret_version.this.secret_string)["db_name"]
  sensitive   = true
}
