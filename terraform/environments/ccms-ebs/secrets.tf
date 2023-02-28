#### This file can be used to store secrets specific to the member account ####

resource "aws_secretsmanager_secret" "secret_ftp_s3" {
  name        = "ftp-s3-${local.environment}-aws-key"
  description = "AWS credentials for mounting of s3 buckets for the FTP Service to access"

  tags = merge(local.tags,
    { Name = "ftp-s3-${local.environment}-aws-key" }
  )
}
