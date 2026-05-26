resource "aws_secretsmanager_secret" "pagerduty_integration_key" {
  name        = "pagerduty/high-priority-alarms/integration-key"
  description = "PagerDuty integration key for high priority security alarms"
  tags        = local.tags
}

resource "aws_secretsmanager_secret_version" "pagerduty_integration_key" {
  secret_id     = aws_secretsmanager_secret.pagerduty_integration_key.id
  secret_string = "CHANGE_ME_IN_THE_CONSOLE"

  lifecycle {
    ignore_changes = [secret_string]
  }
}

# Fetches the live integration key (including any manual updates made in the Console).
data "aws_secretsmanager_secret_version" "pagerduty_integration_key" {
  secret_id  = aws_secretsmanager_secret.pagerduty_integration_key.id
  depends_on = [aws_secretsmanager_secret_version.pagerduty_integration_key]
}