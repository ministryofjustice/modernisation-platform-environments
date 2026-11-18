locals {
  gc_platform_query_teams = local.environment == "development" ? toset([
    "modernisation-platform",
    "cloud-platform",
  ]) : toset([])

  # Upstream account names are <definition filename stem>-<environment name>. The suffix is a
  # single token; confirm the full name against the file instead of trusting the split alone.
  gc_account_name_pattern = "^([a-z0-9][a-z0-9-]*)-[a-z0-9]+$"
  gc_account_definition_stems = {
    for account in keys(local.gc_accounts) : account => regex(local.gc_account_name_pattern, account)[0]
    if length(local.gc_platform_query_teams) > 0 && can(regex(local.gc_account_name_pattern, account))
  }
  gc_account_definitions = {
    for stem, definition in data.http.gc-account-definition : stem => jsondecode(definition.response_body)
    if definition.status_code == 200
  }
  gc_declared_account_names = {
    for stem, definition in local.gc_account_definitions : stem => [
      for environment in definition.environments : "${stem}-${environment.name}"
    ]
  }
  gc_account_applications = {
    for account, stem in local.gc_account_definition_stems : account => try(local.gc_account_definitions[stem].tags.application, null)
    if contains(lookup(local.gc_declared_account_names, stem, []), account) && nonsensitive(
      contains(keys(local.environment_management.account_ids), account) &&
      !contains(keys(local.nonmp_account_ids), account)
    )
  }

  gc_platform_query_team_by_account = {
    for account, application in local.gc_account_applications : account => (
      application == "modernisation-platform" ? "modernisation-platform" :
      try(startswith(application, "container-platform-"), false) ? "cloud-platform" : null
    )
  }
}

# Read only the definitions needed by onboarded accounts, using the same public source as platform_data.tf.
data "http" "gc-account-definition" {
  for_each = toset(values(local.gc_account_definition_stems))

  url = "https://raw.githubusercontent.com/ministryofjustice/modernisation-platform/main/environments/${each.key}.json"

  lifecycle {
    postcondition {
      condition     = contains([200, 404], self.status_code)
      error_message = "Could not read the Modernisation Platform account definition for ${each.key}."
    }
  }
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
