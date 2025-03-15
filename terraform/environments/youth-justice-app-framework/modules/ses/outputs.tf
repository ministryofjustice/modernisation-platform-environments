output "ses_secret_arn" {
  description = "The ARN of the SES SMTP secret"
  value       = aws_secretsmanager_secret.ses_user_secret.arn
}
