locals {
  environment_configuration = local.environment_configurations[local.environment]
  environment_configurations = {
    development = {
      monitoring_stack_enabled = true
      monitoring_hostname      = "monitoring.development.data-platform.service.justice.gov.uk"
      grafana_namespace        = "data-platform-monitoring-development"
      grafana_chart_version    = "12.4.8"

      # Let the grafana provider manage dashboards as code (grafana-dashboards.tf).
      # Keep false until a valid service-account token is stored in the
      # monitoring/grafana-api-token secret; flip to true to start managing them.
      grafana_dashboards_enabled = true

      # Accounts Grafana reads by assuming the data-platform-monitoring role in
      # each (defined in ../modules/monitoring). Account IDs are resolved by name
      # from the Modernisation Platform environment_management map in
      # helm-release.tf, so only the name is listed here. Every account exposes
      # CloudWatch and X-Ray; set prometheus_workspace_id to an account's Amazon
      # Managed Prometheus workspace ID (ws-...) to add a Prometheus data source,
      # or leave it empty to omit one.
      grafana_monitored_accounts = [
        { name = "data-platform-development", prometheus_workspace_id = "ws-1103e531-1155-4d18-ad5f-87ba29e2a38b7a" },
        { name = "data-platform-test", prometheus_workspace_id = "ws-80d995fc-475d-4232-ad3f-80e2342e428902" },
        { name = "data-platform-preproduction", prometheus_workspace_id = "ws-007c0bbe-4cc7-484b-a012-0105073723ba72" },
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

      # Let the grafana provider manage dashboards as code (grafana-dashboards.tf).
      # Keep false until a valid service-account token is stored in the
      # monitoring/grafana-api-token secret; flip to true to start managing them.
      grafana_dashboards_enabled = true

      grafana_monitored_accounts = [
        { name = "data-platform-production", prometheus_workspace_id = "ws-d3a32572-9e85-49f9-8654-bffcf5877783a2" },
      ]
    }
  }
}
