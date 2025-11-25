#### This file can be used to store secrets specific to the member account ####

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

# Slack Channel ID for guardduty Alerts
resource "aws_secretsmanager_secret" "guardduty_slack_channel_id" {
  name        = "guardduty_slack_channel_id"
  description = "Slack Channel ID for guardduty Alerts"
}

data "aws_secretsmanager_secret_version" "guardduty_slack_channel_id" {
  secret_id = aws_secretsmanager_secret.guardduty_slack_channel_id.id
}

# Slack Channel Webhook Secret for EDRMS Docs Exception
resource "aws_secretsmanager_secret" "edrms_docs_exception_secrets" {
  name        = "${local.application_name}-docs-exception-secrets"
  description = "EDRMS Docs Exception Secret"
}

resource "aws_secretsmanager_secret_version" "edrms_docs_exception_secrets" {
  secret_id = aws_secretsmanager_secret.edrms_docs_exception_secrets.id
  secret_string = jsonencode({
    "slack_channel_webhook" = ""
  })

  lifecycle {
    ignore_changes = [
      secret_string
    ]
  }
}
