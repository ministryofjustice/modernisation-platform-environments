resource "litellm_team" "teams" {
  for_each = try(local.ai_gateway_configuration.teams, {})

  team_alias      = try(each.value.alias, each.key)
  organization_id = litellm_organization.organisations[each.value.organisation].id
  budget_duration = try(each.value.budget_duration, "monthly")
  max_budget      = try(each.value.max_budget, 500)
  models          = try(each.value.models, null)
  model_aliases = try(
    { for item in each.value.model_aliases : item.alias => item.model },
    tomap(each.value.model_aliases),
    null
  )

  depends_on = [litellm_organization.organisations]
}
