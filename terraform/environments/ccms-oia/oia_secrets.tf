# AWS Secrets Manager - OIA Secrets

# OIA AWS Secrets

resource "aws_secretsmanager_secret" "oia_secrets" {
  name        = "${local.application_name}-secrets"
  description = "OIA Secrets"
}

resource "aws_secretsmanager_secret_version" "oia_secrets" {
  secret_id = aws_secretsmanager_secret.oia_secrets.id
  secret_string = jsonencode({
    "guardduty_slack_channel_id"  = "",
    "cloudwatch_slack_channel_id" = ""
  })

  lifecycle {
    ignore_changes = [
      secret_string
    ]
  }
}

data "aws_secretsmanager_secret_version" "oia_secrets" {
  secret_id = aws_secretsmanager_secret.oia_secrets.id
}