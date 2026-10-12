#------------------------------------------------------------------------------
# OpenSearch tenant model — per-BU index isolation on the shared cluster.
# Data model only; enforcement resources are phase 2 (see below).
# Follows the per-workspace + phase-2-gate pattern from grafana-objects.tf (#8509).
# Rationale: ADR-017-opensearch-deployment-model.
#------------------------------------------------------------------------------

locals {
  # Index names carry BU and environment, so live/non-live stay separate: <bu>-<env>-*.
  opensearch_env_label = local.opensearch_is_live ? "live" : "non-live"

  # Per-workspace: each BU and the Identity Center groups that may read it.
  opensearch_bus_by_workspace = {
    cloud-platform-development = {
      hmpps = { idc_group_names = ["cloud-platform-engineers"] }        # simulated BU A
      laa   = { idc_group_names = ["container-platform-user-testing"] } # simulated BU B
    }
  }

  opensearch_bus = {
    for bu, cfg in lookup(local.opensearch_bus_by_workspace, terraform.workspace, {}) :
    bu => merge(cfg, { index_pattern = "${bu}-${local.opensearch_env_label}-*" })
  }

  # Phase-2 gate (like local.grafana_objects_enabled): false until the domain exists.
  opensearch_objects_enabled = local.enable_opensearch && lookup(local.environment_configuration, "opensearch_objects_enabled", false)
}

# Enforcement (roles, mappings, ISM) is phase 2 — needs the `opensearch` provider
# against a live domain. Tracked on #8592.
