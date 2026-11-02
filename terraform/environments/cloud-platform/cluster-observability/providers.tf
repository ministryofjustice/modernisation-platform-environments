# The URL comes from the pipeline and auth from GRAFANA_AUTH, so the provider
# can be configured at plan time. Both are unset where AMG is not deployed.
provider "grafana" {
  url = var.grafana_url == "" ? null : "https://${var.grafana_url}"
}
