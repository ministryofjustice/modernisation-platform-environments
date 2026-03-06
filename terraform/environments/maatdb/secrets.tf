#### This file can be used to store secrets specific to the member account ####
resource "aws_secretsmanager_secret" "maatdb_maintenance_slack_secrets" {
  name        = "${local.application_name}-${local.environment}-rds-maintenance-slack"
  description = "Slack webhooks for RDS maintenance notifications"

  tags = merge(local.tags, {
    Name = "${local.application_name}-${local.environment}-rds-maintenance-slack"
  })
}

resource "aws_secretsmanager_secret_version" "maatdb_maintenance_slack_secrets_value" {
  secret_id = aws_secretsmanager_secret.maatdb_maintenance_slack_secrets.id

  secret_string = jsonencode({
    "slack_channel_webhook_crimeapps"   = "",
    "slack_channel_webhook_maatdb_dbas" = ""
  })
}