resource "litellm_team" "teams" {
  for_each = local.environment_configuration.llm_gateway_teams

  organization_id = local.environment_configuration.litellm_organization_ids[each.value.organisation]
  team_alias      = each.key
  models          = each.value.models

  max_budget      = try(each.value.max_budget, 1000)
  budget_duration = try(each.value.budget_duration, "monthly")

  depends_on = [helm_release.litellm]
}

resource "litellm_key" "keys" {
  for_each = merge([
    for team_key, team_value in local.environment_configuration.llm_gateway_teams : {
      for key_name, key_value in team_value.keys : "${team_key}-${key_name}" => {
        team_key = team_key
        key_name = key_name
        models   = key_value.models
      }
    }
  ]...)

  key_alias       = "${each.value.team_key}-${each.value.key_name}"
  team_id         = litellm_team.teams[each.value.team_key].id
  models          = each.value.models
  max_budget      = try(each.value.max_budget, 100)
  budget_duration = try(each.value.budget_duration, "1mo")

  rpm_limit             = try(each.value.rpm_limit, 100)
  tpm_limit             = try(each.value.tpm_limit, 1000)
  max_parallel_requests = try(each.value.max_parallel_requests, 10)

  depends_on = [helm_release.litellm]
}
