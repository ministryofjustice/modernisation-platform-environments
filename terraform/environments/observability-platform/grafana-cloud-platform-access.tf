locals {
  gc_platform_query_teams = toset([
    "modernisation-platform",
    "cloud-platform",
  ])
}

module "grafana_cloud_account_ownership" {
  source = "./modules/grafana-cloud/account-ownership"

  enabled                              = length(local.gc_platform_query_teams) > 0
  accounts                             = toset(keys(local.gc_accounts))
  modernisation_platform_account_names = nonsensitive(toset(keys(local.environment_management.account_ids)))
  nonmp_account_names                  = nonsensitive(toset(keys(local.nonmp_account_ids)))
}

resource "grafana_team" "platform-query" {
  for_each = local.gc_platform_query_teams
  provider = grafana.stack

  name = each.key
}

resource "grafana_team_external_group" "platform-query" {
  for_each = grafana_team.platform-query
  provider = grafana.stack

  team_id = each.value.id
  groups  = ["@ministryofjustice/${each.key}"]
}

# Explorer opens Explore/Drilldown but does not grant query access to any data source.
data "grafana_role" "platform-explorer" {
  count    = length(local.gc_platform_query_teams) > 0 ? 1 : 0
  provider = grafana.stack

  name = "fixed:datasources:explorer"
}

resource "grafana_role_assignment_item" "platform-explorer" {
  for_each = grafana_team.platform-query
  provider = grafana.stack

  role_uid = data.grafana_role.platform-explorer[0].uid
  team_id  = each.value.id
}
