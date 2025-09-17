locals {
  #checkov:skip=CKV_SECRET_6 placeholder
  servicenow_credentials_placeholder = { "USERNAME" : "placeholder", "PASSWORD" : "placeholders" }
  underscore_env                     = local.is-production ? "" : "_${local.environment_shorthand}"
}

resource "aws_secretsmanager_secret" "servicenow_credentials" {
  #checkov:skip=CKV2_AWS_57: “Ignore - Ensure Secrets Manager secrets should have automatic rotation enabled"
  #checkov:skip=CKV_AWS_149: "Ensure that Secrets Manager secret is encrypted using KMS CMK"
  name                    = "credentials/servicenow"
  recovery_window_in_days = 0

  tags = merge(
    local.tags
  )
}

resource "aws_secretsmanager_secret_version" "servicenow_credentials" {
  secret_id     = aws_secretsmanager_secret.servicenow_credentials.id
  secret_string = jsonencode(local.servicenow_credentials_placeholder)

  lifecycle {
    ignore_changes = [secret_string, ]
  }

  depends_on = [aws_secretsmanager_secret.servicenow_credentials]
}
