data "aws_secretsmanager_secret_version" "slack_token" {
  secret_id = "grafana/notifications/slack-token"
}

resource "grafana_contact_point" "this" {
  name = "${var.channel}-slack"

  slack {
    recipient = var.channel
    token     = data.aws_secretsmanager_secret_version.slack_token.secret_string
  }
}
