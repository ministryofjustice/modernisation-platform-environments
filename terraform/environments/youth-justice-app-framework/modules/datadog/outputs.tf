output "datadog_api_key_arn" {
  description = "The ARN of the secret that holds the Datadog Api Key."
  value       = aws_secretsmanager_secret.datadog_api.arn
}

