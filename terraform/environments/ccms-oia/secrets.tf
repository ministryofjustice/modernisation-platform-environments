#### This file stores secrets specific to the ccms-oia application ####

# Database password for OIA
resource "aws_secretsmanager_secret" "db_password" {
  name        = "ccms/oia/datasource"
  description = "OIA database password for CCMS OIA application"
}

data "aws_secretsmanager_secret_version" "db_password" {
  secret_id = aws_secretsmanager_secret.db_password.id
}

# Slack Channel ID for Alerts (optional, keep if needed for monitoring)
resource "aws_secretsmanager_secret" "slack_channel_id" {
  name        = "alerts_slack_channel_id"
  description = "Slack Channel ID for OIA Alerts"
}

data "aws_secretsmanager_secret_version" "slack_channel_id" {
  secret_id = aws_secretsmanager_secret.slack_channel_id.id
}
