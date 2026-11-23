resource "aws_secretsmanager_secret" "fin_transfer" {
  name        = "${local.fin_transfer_name}-secrets"
  description = "Financial Transfers API Application Secrets"
  kms_key_id  = aws_kms_key.fin_transfer.arn
}

resource "aws_secretsmanager_secret_version" "fin_transfer" {
  secret_id = aws_secretsmanager_secret.fin_transfer.id
  secret_string = jsonencode({
    ORACLE_URL              = ""
    ORACLE_PASSWORD         = ""
    ORACLE_USERNAME         = ""
    SLACK_WEBHOOK           = ""
    ENABLE_SWAGGER          = ""
    AUTHORIZED_CLIENTS      = ""
    AUTHORIZED_ROLES        = ""
    UNPROTECTED_URIS        = ""
    OAUTH2_ISSUER_URI       = ""
    OAUTH2_AUDIENCE         = ""
    OAUTH2_ROLES            = ""
    OAUTH2_UNPROTECTED_URIS = ""
    TLS_KEYSTORE_PASSWORD   = ""
  })

  lifecycle {
    ignore_changes = [secret_string]
  }
}

resource "aws_secretsmanager_secret" "process_file_lambda" {
  name        = "${local.fin_transfer_name}-lambda-secrets"
  description = "Process File From Bucket Lambda Secrets"
  kms_key_id  = aws_kms_key.fin_transfer.arn
}

resource "aws_secretsmanager_secret_version" "process_file_lambda" {
  secret_id = aws_secretsmanager_secret.process_file_lambda.id
  secret_string = jsonencode({
    validate_file                      = ""
    financial_transfers_api_key        = ""
    financial_transfers_api_url        = ""
    financial_transfer_api_auth_header = ""
    slack_webhook_url                  = ""
  })

  lifecycle {
    ignore_changes = [secret_string]
  }
}
