output "secret_arn" {
  value       = aws_secretsmanager_secret.this.arn
  description = "The ARN of the secret"
}

output "secret_id" {
  value       = aws_secretsmanager_secret.this.id
  description = "The ID of the secret"
}

output "secret_name" {
  value       = aws_secretsmanager_secret.this.name
  description = "The name of the secret"
}

output "secret_version_id" {
  value       = aws_secretsmanager_secret_version.this.version_id
  description = "The ID of the secret version"
}

output "secret_contents_endpoint" {
  description = "The endpoint extracted from the secret string"
  value       = jsondecode(data.aws_secretsmanager_secret_version.this.secret_string)["endpoint"]
  sensitive   = true
}

output "secret_contents_port" {
  description = "The port extracted from the secret string"
  value       = jsondecode(data.aws_secretsmanager_secret_version.this.secret_string)["port"]
  sensitive   = true
}

output "secret_contents_db_name" {
  description = "The db_name extracted from the secret string"
  value       = jsondecode(data.aws_secretsmanager_secret_version.this.secret_string)["db_name"]
  sensitive   = true
}
