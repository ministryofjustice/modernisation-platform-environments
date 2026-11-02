locals {
  environment_configuration = lookup(local.environment_configurations, terraform.workspace, {})

  # AMG is account-level, so it is only deployed in these workspaces.
  amg_host_workspaces = [
    "cloud-platform-live",
    "cloud-platform-development",
  ]
  enable_amg         = contains(local.amg_host_workspaces, terraform.workspace)
  amg_workspace_name = "${terraform.workspace}-observability"

  # Set false on a fresh AMG host until the service account exists, then true.
  grafana_objects_enabled = lookup(local.environment_configuration, "grafana_objects_enabled", false)
}
