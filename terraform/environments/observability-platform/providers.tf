provider "grafana" {
  url  = "https://${module.managed_grafana.workspace_endpoint}"
  auth = aws_grafana_workspace_api_key.automation_key.key
}
