resource "aws_grafana_workspace_service_account_token" "automation" {
  name               = "terraform"
  service_account_id = aws_grafana_workspace_service_account.automation.service_account_id
  seconds_to_live    = 2592000  # 30 days
  workspace_id       = module.managed_grafana.workspace_id
}

provider "grafana" {
  url  = "https://${module.managed_grafana.workspace_endpoint}"
  auth = aws_grafana_workspace_service_account_token.automation.key
}
