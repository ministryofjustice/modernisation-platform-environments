#### This file can be used to store secrets specific to the sftp client account ####
# SFTP BC Application Secrets
resource "aws_secretsmanager_secret" "sftp_secrets" {
  name        = "${local.sftp_suffix}-bc-secrets"
  description = "SFTP bc Ingress Application Secrets"
  kms_key_id  = aws_kms_key.s3_sftp_kms_key.arn
}

resource "aws_secretsmanager_secret_version" "sftp_secrets" {
  secret_id = aws_secretsmanager_secret.sftp_secrets.id
  secret_string = jsonencode({
    ORACLE_URL            = "",
    ORACLE_PASSWORD       = "",
    ORACLE_USERNAME       = "",
    SLACK_WEBHOOK         = "",
    ENABLE_SWAGGER        = "",
    AUTHORIZED_CLIENTS    = "",
    AUTHORIZED_ROLES      = "",
    UNPROTECTED_URIS      = "",
    TLS_KEYSTORE_PASSWORD = ""
  })

  lifecycle {
    ignore_changes = [
      secret_string
    ]
  }
}

data "aws_secretsmanager_secret_version" "sftp_secrets" {
  secret_id = aws_secretsmanager_secret.sftp_secrets.id
}

# SFTP BC Lambda Secrets
resource "aws_secretsmanager_secret" "sftp_lambda_secrets" {
  name        = "${local.sftp_suffix}-bc-lambda-secrets"
  description = "SFTP lambda Secrets"
  kms_key_id  = aws_kms_key.s3_sftp_kms_key.arn
}

resource "aws_secretsmanager_secret_version" "sftp_lambda_secrets" {
  secret_id = aws_secretsmanager_secret.sftp_lambda_secrets.id
  secret_string = jsonencode({
    validate_file                      = "",
    financial_transfers_api_key        = "",
    financial_transfers_api_url        = "",
    financial_transfer_api_auth_header = "",
    slack_webhook_url                  = ""
  })

  lifecycle {
    ignore_changes = [
      secret_string
    ]
  }
}

data "aws_secretsmanager_secret_version" "sftp_lambda_secrets" {
  secret_id = aws_secretsmanager_secret.sftp_lambda_secrets.id
}