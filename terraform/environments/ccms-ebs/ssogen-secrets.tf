# Common EBS Secrets
resource "aws_secretsmanager_secret" "dev_account_secret" {
  count       = local.ssogen_enabled ? 1 : 0
  name        = "${local.application_name}-dev-account-secrets"
  description = "CCMS EBS Secret for dev account"
}

resource "aws_secretsmanager_secret_version" "dev_account_secret" {
  count     = local.ssogen_enabled ? 1 : 0
  secret_id = aws_secretsmanager_secret.dev_account_secret[count.index].id

  secret_string = jsonencode({
    "dev_account_id"     = "",
    "preprod_account_id" = "",
    "prod_account_id"    = ""
  })

  lifecycle {
    ignore_changes = [
      secret_string
    ]
  }
}

data "aws_secretsmanager_secret_version" "dev_account_secret" {
  count     = local.ssogen_enabled ? 1 : 0
  secret_id = aws_secretsmanager_secret.dev_account_secret[count.index].id
}
