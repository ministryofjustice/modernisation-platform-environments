# Shared Grafana Cloud Metrics (Mimir), Logs (Loki) and Traces (Tempo) data sources, named
# "shared-metrics", "shared-logs" and "shared-traces". Created once an account in this environment
# pushes to Grafana Cloud (its `push` setting in grafana-cloud-tenant-environment-configurations.tf).
#
# Every account pushes to the stack's one set of stores, so all teams share these data sources.
# Label-based access control rules keep teams apart: a team only sees data from the accounts it can
# query (its tenant's accounts and those shared with it) that push the signal.

locals {
  gc_shared_data_sources_enabled = length(local.gc_push_signals) > 0
}

# Read only, with no label selectors: they would take precedence over the data sources' label-based
# access control rules.
resource "grafana_cloud_access_policy" "shared_read" {
  count    = local.gc_shared_data_sources_enabled ? 1 : 0
  provider = grafana.cloud

  name         = "${grafana_cloud_stack.observability_platform.slug}-shared-read"
  display_name = "Shared data sources (${grafana_cloud_stack.observability_platform.slug})"
  region       = grafana_cloud_stack.observability_platform.region_slug
  scopes       = ["metrics:read", "logs:read", "traces:read"]

  realm {
    type       = "stack"
    identifier = grafana_cloud_stack.observability_platform.id
  }
}

# No expiry, as for the PDC tokens. Replace the token to rotate it.
resource "grafana_cloud_access_policy_token" "shared_read" {
  count    = local.gc_shared_data_sources_enabled ? 1 : 0
  provider = grafana.cloud

  name             = "${grafana_cloud_access_policy.shared_read[0].name}-data-sources"
  display_name     = "Shared data sources (${grafana_cloud_stack.observability_platform.slug})"
  access_policy_id = grafana_cloud_access_policy.shared_read[0].policy_id
  region           = grafana_cloud_access_policy.shared_read[0].region
}

module "grafana_cloud_shared_data_sources" {
  count  = local.gc_shared_data_sources_enabled ? 1 : 0
  source = "./modules/grafana-cloud/shared-data-sources"

  providers = {
    grafana = grafana.stack
  }

  stack_slug = grafana_cloud_stack.observability_platform.slug
  read_token = grafana_cloud_access_policy_token.shared_read[0].token
  metrics = {
    url      = grafana_cloud_stack.observability_platform.prometheus_remote_endpoint
    username = grafana_cloud_stack.observability_platform.prometheus_user_id
  }
  logs = {
    url      = grafana_cloud_stack.observability_platform.logs_url
    username = grafana_cloud_stack.observability_platform.logs_user_id
  }
  traces = {
    url      = "${grafana_cloud_stack.observability_platform.traces_url}/tempo"
    username = grafana_cloud_stack.observability_platform.traces_user_id
  }

  # Each tenant's team, with the accounts it can query that push each signal. Only tenants with a
  # GitHub team have a Grafana team.
  teams = {
    for tenant_name, team in module.grafana_cloud_team : tenant_name => {
      id  = team.team_id
      uid = team.team_uid
      accounts = {
        for signal in ["metrics", "logs", "traces"] : signal => [
          for account_name in local.gc_tenants[tenant_name].query_accounts :
          account_name if local.gc_accounts[account_name].push[signal]
        ]
      }
    }
  }
  account_ids = local.gc_push_accounts
}
