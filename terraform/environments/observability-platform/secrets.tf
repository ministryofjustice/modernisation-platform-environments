resource "aws_secretsmanager_secret" "grafana_api_key" {
  name = "grafana/api-key"
}
