locals {
  environment_configuration = local.environment_configurations[local.environment]
  environment_configurations = {
    development = {
      monitoring_stack_enabled = true
      monitoring_hostname      = "monitoring.development.data-platform.service.justice.gov.uk"
      grafana_namespace        = "data-platform-monitoring-development"
      grafana_chart_version    = "12.4.8"

      # Accounts Grafana reads by assuming the data-platform-monitoring role in
      # each (defined in ../modules/monitoring). Every account exposes CloudWatch
      # and X-Ray. The data-platform (non-governance) accounts also run Amazon
      # Managed Prometheus, so set prometheus_workspace_id to each one's AMP
      # workspace ID (ws-...) to add a Prometheus data source; governance
      # accounts have no AMP workspace and keep it empty.
      grafana_monitored_accounts = [
        { name = "data-platform-development", account_id = "013433889002", prometheus_workspace_id = "ws-1103e531-1155-4d18-ad5f-87ba29e2a38b7a" },
        { name = "data-platform-test", account_id = "259787491607", prometheus_workspace_id = "ws-80d995fc-475d-4232-ad3f-80e2342e428902" },
        { name = "data-platform-preproduction", account_id = "386657846332", prometheus_workspace_id = "ws-007c0bbe-4cc7-484b-a012-0105073723ba72" },
        { name = "data-platform-governance-development", account_id = "883644721336", prometheus_workspace_id = "" },
        { name = "data-platform-governance-test", account_id = "584108277778", prometheus_workspace_id = "" },
        { name = "data-platform-governance-preproduction", account_id = "960979851195", prometheus_workspace_id = "" },
      ]
    }
    test = {
      monitoring_stack_enabled = false
    }
    preproduction = {
      monitoring_stack_enabled = false
    }
    production = {
      monitoring_stack_enabled = true
      monitoring_hostname      = "monitoring.data-platform.service.justice.gov.uk"
      grafana_namespace        = "data-platform-monitoring-production"
      grafana_chart_version    = "12.4.8"

      grafana_monitored_accounts = [
        { name = "data-platform-production", account_id = "209019631331", prometheus_workspace_id = "ws-d3a32572-9e85-49f9-8654-bffcf5877783a2" },
        { name = "data-platform-governance-production", account_id = "190028274816", prometheus_workspace_id = "" },
      ]
    }
  }
}
