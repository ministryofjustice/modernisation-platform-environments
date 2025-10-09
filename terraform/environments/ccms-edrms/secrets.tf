#### This file can be used to store secrets specific to the member account ####

resource "aws_secretsmanager_secret" "edrms_secret" {
  name        = "edrms-secret"
  description = "EDRMS secret for CCMS EDRMS application"
}

resource "aws_secretsmanager_secret_version" "edrms_secret_version" {
  secret_id = aws_secretsmanager_secret.edrms_secret.id
  secret_string = jsonencode({
     "ccms/edrms/datasource" = "secret1"
     "alerts_slack_channel_id" = "secret2"
  })
}

resource "aws_secretsmanager_secret" "spring_datasource_password" {
  name        = "ccms/edrms/datasource"
  description = "EDRMS TDS database password for CCMS EDRMS application"
}



data "aws_secretsmanager_secret_version" "spring_datasource_password" {
  secret_id = aws_secretsmanager_secret.spring_datasource_password.id
}

# Slack Channel ID for Alerts
resource "aws_secretsmanager_secret" "slack_channel_id" {
  name        = "alerts_slack_channel_id"
  description = "Slack Channel ID for EDRMS Alerts"
}

data "aws_secretsmanager_secret_version" "slack_channel_id" {
  secret_id = aws_secretsmanager_secret.slack_channel_id.id
}