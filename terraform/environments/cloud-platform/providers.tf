# Grafana provider — manages Grafana-internal objects in the centralised AMG
# workspace (teams, data sources, data-source permissions, folders) for BU
# metric isolation (cloud-platform#8509).
#
# Provider configuration must be resolvable at plan time, so neither input comes
# from a resource in this apply:
#   - url:  passed in as var.grafana_url by the pipeline (from the workspace
#           endpoint). Empty on workspaces that do not host AMG.
#   - auth: read from the GRAFANA_AUTH environment variable, which the pipeline
#           sets to a short-lived AMG service account token (max 30 days; minted
#           per run, never stored).
#
# On workspaces where AMG is not deployed, var.grafana_url is empty and every
# Grafana resource is gated off by local.enable_amg, so the provider is
# configured but never invoked. This mirrors how the kubernetes/helm/kubectl
# providers in the cluster-* components are configured with try(..., null) and
# left unused where no cluster exists.
provider "grafana" {
  url = var.grafana_url == "" ? null : "https://${var.grafana_url}"
}
