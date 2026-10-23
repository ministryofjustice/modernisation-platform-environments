#------------------------------------------------------------------------------
# OpenSearch per-BU index isolation on the shared cluster (cloud-platform#8592).
# Same pattern as grafana-objects.tf (#8509). Design: ADR-017, OpenSearch section.
#
# For each BU: an index template for its daily indexes (<bu>-<env>-*), a
# read-only role scoped to those indexes, and a role mapping that grants it to
# the BU's Identity Center groups. Groups are matched by NAME because the
# domain's roles key is GroupName.
#
# Not managed here, on purpose:
#   - The built-in all_access / security_manager mappings. They hold the admin
#     SSO role, MemberInfrastructureAccess and the admin groups; taking them over
#     risks removing admin access. Leave them as they are.
#   - The write side (who may write logs). For the direct route it is per
#     cluster, in cluster-components; the route itself is still open (#8623).
#------------------------------------------------------------------------------

locals {
  # Index names carry BU and environment, so live/non-live stay separate: <bu>-<env>-*.
  opensearch_env_label = local.opensearch_is_live ? "live" : "non-live"

  # Real BUs from the shared business-units.json (#8558), the same list Grafana
  # uses, so both grant the same groups. local.business_units is loaded in
  # grafana-objects.tf.
  opensearch_bus_real = {
    for k, bu in local.business_units : k => { idc_group_names = [bu.parent_group] }
  }

  # Dev-only simulated BUs, so isolation can be tested on the dev domain with
  # groups we can sign in with. Kept out of business-units.json on purpose.
  opensearch_simulated_bus_dev = {
    hmpps = { idc_group_names = ["cloud-platform-engineers"] }        # simulated BU A
    laa   = { idc_group_names = ["container-platform-user-testing"] } # simulated BU B
  }

  opensearch_bus_by_workspace = {
    cloud-platform-development = local.opensearch_simulated_bus_dev
    cloud-platform-nonlive     = local.opensearch_bus_real
    cloud-platform-live        = local.opensearch_bus_real
  }

  opensearch_bus = {
    for bu, cfg in lookup(local.opensearch_bus_by_workspace, terraform.workspace, {}) :
    bu => merge(cfg, { index_pattern = "${bu}-${local.opensearch_env_label}-*" })
  }

  # Phase-2 gate for the S3 -> OSIS ingestion pipeline (opensearch-ingestion.tf).
  # Kept as-is; it is NOT the gate for the roles below.
  opensearch_objects_enabled = local.enable_opensearch && lookup(local.environment_configuration, "opensearch_objects_enabled", false)

  # Separate gate for roles and mappings, so turning them on doesn't also try to
  # build the ingestion pipeline. Off by default. Before switching on: map the
  # apply role to security_manager by hand (one-off bootstrap, see #8592).
  opensearch_roles_enabled = local.enable_opensearch && lookup(local.environment_configuration, "opensearch_roles_enabled", false)

  opensearch_roles_bus = local.opensearch_roles_enabled ? local.opensearch_bus : {}
}

# Read only when roles are on, so it never runs before the domain exists. Feeds
# the provider URL (providers.tf).
data "aws_opensearch_domain" "logs" {
  count       = local.opensearch_roles_enabled ? 1 : 0
  domain_name = local.opensearch_domain_name
}

# One index template per BU, created ahead of any cluster. Fluent Bit writes a
# new index each day, so a template (not a fixed index) is what makes every
# daily <bu>-<env>-YYYY.MM.DD index get the same settings and field types.
# Replicas follow the data-node count: 0 on the single-node dev domain (no
# unplaceable copy, so no "yellow" health), 1 where there are two nodes.
resource "opensearch_index_template" "bu" {
  for_each = local.opensearch_roles_bus

  name = "${each.key}-${local.opensearch_env_label}-logs"
  body = jsonencode({
    index_patterns = [each.value.index_pattern]
    priority       = 100
    template = {
      settings = {
        index = {
          number_of_shards   = "1"
          number_of_replicas = local.opensearch_data_nodes > 1 ? "1" : "0"
        }
      }
      mappings = {
        properties = {
          "@timestamp" = { type = "date" }
        }
      }
    }
  })
}

# Read-only access to one BU's indexes. Default-deny: no other index patterns.
resource "opensearch_role" "bu_read" {
  for_each = local.opensearch_roles_bus

  role_name   = "${each.key}-${local.opensearch_env_label}-read"
  description = "Read-only access to ${each.value.index_pattern} (#8592)"

  cluster_permissions = ["cluster_composite_ops_ro", "cluster_monitor"]

  index_permissions {
    index_patterns  = [each.value.index_pattern]
    allowed_actions = ["read", "search", "indices_monitor"]
  }
}

resource "opensearch_roles_mapping" "bu_read" {
  for_each = local.opensearch_roles_bus

  role_name     = opensearch_role.bu_read[each.key].role_name
  description   = "Identity Center groups for ${each.key} (#8592)"
  backend_roles = each.value.idc_group_names
}
