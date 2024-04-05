resource "aws_secretsmanager_secret" "grafana_api_key" {
  name = "grafana/api-key"
}

resource "aws_secretsmanager_secret" "github_token" {
  name = "grafana/data-sources/github-token"
}

resource "aws_secretsmanager_secret" "slack_token" {
  name = "grafana/notifications/slack-token"
}

resource "aws_secretsmanager_secret" "pagerduty_integration_keys" {
  name = "grafana/notifications/pagerduty-integration-keys"
}
