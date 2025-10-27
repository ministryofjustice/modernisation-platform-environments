# Find all JSON files in the dashboards folder
locals {
  dashboard_files = fileset("${path.module}/dashboards", "*.json")
}

# Create a grafana_dashboard for each JSON file
resource "grafana_dashboard" "all" {
  for_each    = local.dashboard_files
  config_json = file("${path.module}/dashboards/${each.value}")
}