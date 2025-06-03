locals {
  allied_account_id_placeholder = "placeholder"
}

resource "aws_secretsmanager_secret" "allied_account_id" {
  #checkov:skip=CKV2_AWS_57: “Ignore - Ensure Secrets Manager secrets should have automatic rotation enabled"
  #checkov:skip=CKV_AWS_149: "Ensure that Secrets Manager secret is encrypted using KMS CMK"
  name                    = "account_ids/allied"
  recovery_window_in_days = 0

  tags = merge(
    local.tags
  )
}

resource "aws_secretsmanager_secret_version" "allied_account_id" {
  secret_id     = aws_secretsmanager_secret.allied_account_id.id
  secret_string = jsonencode(local.allied_account_id_placeholder)

  lifecycle {
    ignore_changes = [secret_string, ]
  }

  depends_on = [aws_secretsmanager_secret.allied_account_id]
}
