resource "litellm_team" "teams" {
  for_each = local.environment_configuration.ai_gateway_configuration.teams

  team_alias      = each.value.team_alias
  organization_id = litellm_organization.organisations[each.value.organization_name].id

  depends_on = [litellm_organization.organisations]
}
