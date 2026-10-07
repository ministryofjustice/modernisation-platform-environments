#------------------------------------------------------------------------------
# OpenSearch tenant model — per-BU index isolation on the shared cluster.
# Data model only; the enforcement resources are phase 2 (see below).
# Mirrors grafana-objects.tf (#8509). Rationale: ADR-017-opensearch-deployment-model.
#------------------------------------------------------------------------------

locals {
  # Per-workspace: each BU -> its index pattern (Fluent Bit writes bu-<name>-*)
  # and the Identity Center group names whose members may read it.
  opensearch_bus_by_workspace = {
    cloud-platform-development = {
      bu1 = {
        index_pattern   = "bu-bu1-*"
        idc_group_names = ["cloud-platform-engineers"] # simulated BU A
      }
      bu2 = {
        index_pattern   = "bu-bu2-*"
        idc_group_names = ["container-platform-user-testing"] # simulated BU B
      }
    }
  }

  opensearch_bus = lookup(local.opensearch_bus_by_workspace, terraform.workspace, {})

  # Phase-2 gate, like local.grafana_objects_enabled: stays false until the
  # domain exists and the `opensearch` provider is configured against it.
  opensearch_objects_enabled = local.enable_opensearch && lookup(local.environment_configuration, "opensearch_objects_enabled", false)
}

# Phase 2 (not active) — behind the `opensearch` provider, for_each over
# local.opensearch_bus: opensearch_role (read own index only), roles_mapping
# (IdC groups), Fluent Bit write mapping (#8419), ISM per index. Deferred because
# the provider needs a reachable endpoint, which doesn't exist until apply.
