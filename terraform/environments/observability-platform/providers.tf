provider "grafana" {
  url  = "https://${module.managed_grafana.workspace_endpoint}"
  auth = data.aws_secretsmanager_secret_version.grafana_api_key.secret_string
}

provider "grafana" {
  alias                     = "cloud"
  cloud_access_policy_token = data.aws_secretsmanager_secret_version.grafana_cloud_access_policy_token.secret_string
}
