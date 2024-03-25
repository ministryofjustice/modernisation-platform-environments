data "aws_secretsmanager_secret_version" "github_token" {
  secret_id = "grafana/notifications/slack-token"
}

resource "grafana_contact_point" "this" {
  name = "${var.team_name}-${var.channel}-slack"

  slack {
    recipient = var.channel
    token     = data.aws_secretsmanager_secret_version.github_token.secret_string
  }
}
