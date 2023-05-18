### This file can be used to store secrets specific to the member account. ###

resource "aws_secretsmanager_secret" "secret_ftp_s3" {
  name        = "ftp-s3-${local.environment}-aws-key"
  description = "AWS credentials for mounting of s3 buckets for the FTP Service to access"

  tags = merge(local.tags,
    { Name = "ftp-s3-${local.environment}-aws-key" }
  )
}

resource "aws_secretsmanager_secret" "secret_ses_smtp_credentials" {
  name        = "ses-smtp-credentials-${local.environment}"
  description = "SMTP credentials for Postfix to send messages through SES."

  tags = merge(local.tags,
    { Name = "ses-smtp-credentials-${local.environment}" }
  )
}
