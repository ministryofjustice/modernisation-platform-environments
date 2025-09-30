#### This file stores secrets specific to the ccms-oia member account ####

# Database password secret
resource "aws_secretsmanager_secret" "spring_datasource_password" {
  name        = "ccms/oia/mysql/password"
  description = "OIA MySQL database password for CCMS OIA application"
}

data "aws_secretsmanager_secret_version" "spring_datasource_password" {
  secret_id = aws_secretsmanager_secret.spring_datasource_password.id
}

# Slack Channel ID for Alerts
resource "aws_secretsmanager_secret" "slack_channel_id" {
  name        = "alerts_slack_channel_id_oia"
  description = "Slack Channel ID for OIA Alerts"
}

data "aws_secretsmanager_secret_version" "slack_channel_id" {
  secret_id = aws_secretsmanager_secret.slack_channel_id.id
}
