resource "litellm_unified_access_group" "generally_available_models" {
  access_group_name = "generally-available-models"

  access_model_names = concat(
    [
      for key in sort(keys(litellm_model.amazon_bedrock)) :
      litellm_model.amazon_bedrock[key].model_name
      if try(local.ai_gateway_configuration.models.amazon_bedrock[key].generally_available, false)
    ],
    [
      for key in sort(keys(litellm_model.google_gemini_enterprise_agent_platform)) :
      litellm_model.google_gemini_enterprise_agent_platform[key].model_name
      if try(local.ai_gateway_configuration.models.google_gemini_enterprise_agent_platform[key].generally_available, false)
    ],
    [
      for key in sort(keys(litellm_model.microsoft_foundry)) :
      litellm_model.microsoft_foundry[key].model_name
      if try(local.ai_gateway_configuration.models.microsoft_foundry[key].generally_available, false)
    ]
  )

  assigned_team_ids = [
    for team_name in sort(keys(try(local.ai_gateway_configuration.teams, {}))) :
    litellm_team.teams[team_name].id
    if contains(try(local.ai_gateway_configuration.teams[team_name].unified_access_groups, []), "generally-available-models")
  ]
}
