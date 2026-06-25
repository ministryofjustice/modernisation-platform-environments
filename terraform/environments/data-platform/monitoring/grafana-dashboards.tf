# Dashboards and folders managed as code via the Terraform grafana provider
# (configured in providers.tf). Datasources stay provisioned by the Helm chart
# (values.yml.tftpl): a dashboard switches account at the top via its "Account"
# datasource template variable, which selects from those per-account CloudWatch
# datasources at view time, so the dashboard JSON is unchanged by this move.
#
# These resources are created only once a real service-account token has been
# populated in Secrets Manager (local.grafana_dashboards_manageable), which keeps
# terraform plan/apply from reaching an unauthenticated Grafana during the initial
# bootstrap. depends_on orders dashboard creation after the Helm release so
# Grafana is deployed before the provider pushes to it.

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
  # Adopt dashboards that already exist with the same uid (e.g. previously
  # provisioned by the Helm chart) instead of failing on a version conflict.
  overwrite = true

  depends_on = [helm_release.grafana]
}
