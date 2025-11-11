# Find all JSON files in the dashboards folder (including subfolders)
locals {
  # Get all dashboard files recursively
  all_dashboard_files = fileset("${path.module}/dashboards", "**/*.json")

  # Parse each file path to determine team/folder assignment
  dashboard_config = {
    for file in local.all_dashboard_files : file => {
      # Extract team name from path (e.g., "team-name/dashboard.json" -> "team-name")
      team_name = length(split("/", file)) > 1 ? split("/", file)[0] : null
      # Get the folder ID if this dashboard belongs to a team
      folder_id = length(split("/", file)) > 1 ? module.tenant_configuration[split("/", file)[0]].folder_id : null
    }
  }
}

# Create a grafana_dashboard for each JSON file
resource "grafana_dashboard" "all" {
  for_each = local.all_dashboard_files

  config_json = file("${path.module}/dashboards/${each.value}")
  folder      = local.dashboard_config[each.value].folder_id
}