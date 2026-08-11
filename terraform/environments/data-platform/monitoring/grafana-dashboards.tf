# Dashboards/folders are managed by the Grafana provider.
# Datasources remain Helm-provisioned; dashboards switch accounts via the Account variable.
# Resources are gated by local.grafana_dashboards_manageable and created after Helm deploys Grafana.

resource "grafana_folder" "this" {
  for_each = local.grafana_dashboards_manageable ? local.grafana_dashboard_folders : {}

  uid   = each.key
  title = each.value

  depends_on = [helm_release.grafana]
}

resource "grafana_dashboard" "this" {
  for_each = local.grafana_dashboards_manageable ? local.grafana_dashboard_files : {}

  folder      = grafana_folder.this[each.value.folder_key].uid
  config_json = file(each.value.path)
  # Adopt existing dashboards with the same uid instead of failing on version conflicts.
  overwrite = true

  depends_on = [helm_release.grafana]
}
