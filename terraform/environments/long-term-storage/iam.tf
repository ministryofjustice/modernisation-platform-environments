resource "aws_secretsmanager_secret" "s3_user_secret" {
  # checkov:skip=CKV2_AWS_57:Auto rotation not possible
  # checkov:skip=CKV_AWS_149:No requirement currently to encrypt this secret with customer-managed KMS key
  name        = "s3-user-credentials"
  description = "Access and secret key for S3 IAM user"
}