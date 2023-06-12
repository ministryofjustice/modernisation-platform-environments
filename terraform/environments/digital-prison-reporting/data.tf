# KMS Key ID for Kinesis Stream
data "aws_kms_key" "kinesis_kms_key" {
  key_id = aws_kms_key.kinesis-kms-key.arn
}

# Source Nomis Secrets
data "aws_secretsmanager_secret" "nomis" {
  name = "dpr/${local.project}-nomis-source-secrets"
}

data "aws_secretsmanager_secret_version" "nomis" {
  secret_id = data.aws_secretsmanager_secret.nomis.id
}