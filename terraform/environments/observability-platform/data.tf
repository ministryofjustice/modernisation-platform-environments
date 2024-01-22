data "aws_secretsmanager_secret_version" "grafana_api_key" {
  secret_id = aws_secretsmanager_secret.grafana_api_key.id
}
