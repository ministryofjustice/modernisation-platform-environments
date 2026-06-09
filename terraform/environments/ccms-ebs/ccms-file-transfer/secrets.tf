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
    ORACLE_URL         = "",
    ORACLE_PASSWORD    = "",
    ORACLE_USERNAME    = "",
    SLACK_WEBHOOK      = "",
    ENABLE_SWAGGER     = "",
    AUTHORIZED_CLIENTS = "",
    AUTHORIZED_ROLES   = "",
    UNPROTECTED_URIS   = ""
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

moved {
  from = aws_secretsmanager_secret.sftp_bc_secrets
  to   = aws_secretsmanager_secret.sftp_secrets
}

moved {
  from = aws_secretsmanager_secret_version.sftp_bc_secrets
  to   = aws_secretsmanager_secret_version.sftp_secrets
}

# SFTP BC Lambda Secrets
resource "aws_secretsmanager_secret" "sftp_lambda_secrets" {
  name        = "${local.sftp_suffix}-bc-lambda-secrets"
  description = "SFTP lambda Secrets"
  kms_key_id  = aws_kms_key.s3_sftp_kms_key.arn
}

moved {
  from = aws_secretsmanager_secret.sftp_bc_lambda_secrets
  to   = aws_secretsmanager_secret.sftp_lambda_secrets
}

resource "aws_secretsmanager_secret_version" "sftp_lambda_secrets" {
  secret_id = aws_secretsmanager_secret.sftp_lambda_secrets.id
  secret_string = jsonencode({
    validate_file = ""
  })

  lifecycle {
    ignore_changes = [
      secret_string
    ]
  }
}

moved {
  from = aws_secretsmanager_secret_version.sftp_bc_lambda_secrets
  to   = aws_secretsmanager_secret_version.sftp_lambda_secrets
}

data "aws_secretsmanager_secret_version" "sftp_lambda_secrets" {
  secret_id = aws_secretsmanager_secret.sftp_lambda_secrets.id
}