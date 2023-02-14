# Get secret by arn for environment management
data "aws_secretsmanager_secret" "environment_management" {
  provider = aws.modernisation-platform
  name     = "environment_management"
}

# Get latest secret value with ID from above. This secret stores account IDs for the Modernisation Platform sub-accounts
data "aws_secretsmanager_secret_version" "environment_management" {
  provider  = aws.modernisation-platform
  secret_id = data.aws_secretsmanager_secret.environment_management.id
}

resource "aws_secretsmanager_secret" "secret_ftp_s3" {
  name = "ftp-s3-${local.environment}-aws-key"
  description = "AWS credentials for mounting of s3 buckets for the FTP Service to access"

  tags = merge(local.tags,
    { Name = "ftp-s3-${local.environment}-aws-key" }
  )
}