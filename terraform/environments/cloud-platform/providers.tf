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

# OpenSearch provider — manages security roles and role mappings inside the
# shared log domain for per-BU index isolation (cloud-platform#8592). See ADR-017.
#
# Same plan-time rule as Grafana: the URL can't come from a resource created in
# this apply. It comes from a data source that is only read once the domain
# exists and roles are switched on (local.opensearch_roles_enabled). Elsewhere a
# placeholder URL is used: configuring the provider makes no network call, and
# every opensearch_* resource is gated off, so it is never contacted.
#
# Auth is SigV4 with the apply role's AWS credentials. That role must be mapped
# to security_manager inside OpenSearch before the first apply — a one-off
# bootstrap step Terraform can't do for itself (see #8592).
provider "opensearch" {
  url               = local.opensearch_roles_enabled ? "https://${data.aws_opensearch_domain.logs[0].endpoint}" : "https://opensearch-not-enabled.invalid"
  aws_region        = data.aws_region.current.region
  sign_aws_requests = true
  # Health checks and sniffing assume direct node access; a managed domain sits
  # behind an endpoint, so both stay off.
  healthcheck = false
  sniff       = false
}
