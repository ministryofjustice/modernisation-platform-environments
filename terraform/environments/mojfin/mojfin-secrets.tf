resource "random_password" "rds_password" {
  length  = 16
  special = false
}

resource "aws_secretsmanager_secret" "rds_password_secret" {
  name        = "${local.application_name}/app/db-master-password"
  description = "This secret has a dynamically generated password."
  tags = merge(
    local.tags,
    { "Name" = "${local.application_name}/app/db-master-password" },
  )
}

resource "aws_secretsmanager_secret_version" "rds_password_secret_version" {
  secret_id = aws_secretsmanager_secret.rds_password_secret.id
  secret_string = jsonencode(
    {
      username = local.username
      password = random_password.rds_password.result
    }
  )
}

resource "aws_secretsmanager_secret" "mojfin_secret" {
  name                    = "${local.application_name}-${local.environment}-guardduty-slack"
  description             = "Slack webhook URLs for GuardDuty and CloudWatch alerts (laa-alerts-guardduty-nonprod or laa-alerts-guardduty-prod)"
  recovery_window_in_days = local.is-production ? 30 : 0

  tags = merge(local.tags, {
    Name = "${local.application_name}-${local.environment}-guardduty-slack"
  })
}

resource "aws_secretsmanager_secret_version" "mojfin_secret_version" {
  secret_id = aws_secretsmanager_secret.mojfin_secret.id
  secret_string = jsonencode({
    "slack_channel_webhook"           = ""
    "slack_channel_webhook_guardduty" = ""
    "slack_channel_webhook_s3"        = ""
  })

  lifecycle {
    ignore_changes = [secret_string]
  }
}

moved {
  from = aws_secretsmanager_secret.guardduty_slack_secret
  to   = aws_secretsmanager_secret.mojfin_secret
}

moved {
  from = aws_secretsmanager_secret_version.guardduty_slack_secret_version
  to   = aws_secretsmanager_secret_version.mojfin_secret_version
}
