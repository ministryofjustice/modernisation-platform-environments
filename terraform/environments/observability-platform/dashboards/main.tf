# 🔑 Get Grafana API key from AWS Secrets Manager
data "aws_secretsmanager_secret_version" "grafana_api_key" {
  secret_id = "grafana/api-key"
}

# 🎛️ Configure Grafana provider
provider "grafana" {
  url  = aws_grafana_workspace.this.endpoint
  auth = data.aws_secretsmanager_secret_version.grafana_api_key.secret_string
}

# 📊 Example Dashboard
resource "grafana_dashboard" "example" {
  config_json = file("example.json")
}
