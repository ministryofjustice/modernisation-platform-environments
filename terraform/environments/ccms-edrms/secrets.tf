#### This file can be used to store secrets specific to the member account ####

resource "aws_secretsmanager_secret" "edrms_secret" {
  count       = length(local.edrms_secret_values) > 0 ? 1 : 0
  name        = "edrms-secret"
  description = "EDRMS secret for CCMS EDRMS application"
}

resource "aws_secretsmanager_secret_version" "edrms_secret_version" {
  count         = length(local.edrms_secret_values) > 0 ? 1 : 0
  secret_id     = aws_secretsmanager_secret.edrms_secret[0].id
  secret_string = jsonencode(local.edrms_secret_values)
}

data "aws_secretsmanager_secret_version" "edrms_secret_version_current" {
  secret_id = aws_secretsmanager_secret.edrms_secret.id
}

/*
  The combined secret above (resource: aws_secretsmanager_secret.edrms_secret
  with version aws_secretsmanager_secret_version.edrms_secret_version) contains
  both values:
    - ccms/edrms/datasource
    - alerts_slack_channel_id

  Individual per-key secret resources were removed so the code reads both
  keys from the single combined secret via locals (see locals.tf).
*/

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