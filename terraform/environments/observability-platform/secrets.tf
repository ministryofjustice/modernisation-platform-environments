resource "aws_secretsmanager_secret" "grafana_api_key" {
  name = "grafana/api-key"
}

resource "aws_secretsmanager_secret" "github_token" {
  name = "grafana/data-sources/github-token"
}
