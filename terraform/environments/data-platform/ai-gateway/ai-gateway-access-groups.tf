resource "litellm_unified_access_group" "generally_available_models" {
  access_group_name = "generally-available-models"

  access_model_names = concat(
    [
      for key in sort(keys(litellm_model.amazon_bedrock)) :
      litellm_model.amazon_bedrock[key].model_name
      if try(local.ai_gateway_models.amazon_bedrock[key].generally_available, false)
    ],
    [
      for key in sort(keys(litellm_model.google_gemini_enterprise_agent_platform)) :
      litellm_model.google_gemini_enterprise_agent_platform[key].model_name
      if try(local.ai_gateway_models.google_gemini_enterprise_agent_platform[key].generally_available, false)
    ],
    [
      for key in sort(keys(litellm_model.microsoft_foundry)) :
      litellm_model.microsoft_foundry[key].model_name
      if try(local.ai_gateway_models.microsoft_foundry[key].generally_available, false)
    ]
  )
}
