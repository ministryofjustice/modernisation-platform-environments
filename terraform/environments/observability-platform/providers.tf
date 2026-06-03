provider "grafana" {
  url  = "https://${module.managed_grafana.workspace_endpoint}"
  auth = aws_grafana_workspace_service_account_token.automation.key
}
