output "aws_secretsmanager_secret_secret_ftp_s3_arn" {
  description = "aws_secretsmanager_secret secret_ftp_s3 arn"
  value       = aws_secretsmanager_secret.secret_ftp_s3.arn
}

#

output "aws_secretsmanager_secret_secret_ses_smtp_credentials_arn" {
  description = "aws_secretsmanager_secret secret_ses_smtp_credentials arn"
  value       = aws_secretsmanager_secret.secret_ses_smtp_credentials.arn
}
