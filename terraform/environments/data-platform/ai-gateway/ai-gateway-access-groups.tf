resource "litellm_unified_access_group" "amazon_bedrock" {
  for_each = try(local.ai_gateway_models_filtered.amazon_bedrock, {})

  access_group_name  = "bedrock-${each.key}"
  access_model_names = [litellm_model.amazon_bedrock[each.key].model_name]
}

resource "litellm_unified_access_group" "google_gemini_enterprise_agent_platform" {
  for_each = try(local.ai_gateway_models_filtered.google_gemini_enterprise_agent_platform, {})

  access_group_name  = "gemini-${each.key}"
  access_model_names = [litellm_model.google_gemini_enterprise_agent_platform[each.key].model_name]
}

resource "litellm_unified_access_group" "microsoft_foundry" {
  for_each = try(local.ai_gateway_models_filtered.microsoft_foundry, {})

  access_group_name  = "azure-${each.key}"
  access_model_names = [litellm_model.microsoft_foundry[each.key].model_name]
}

resource "litellm_unified_access_group" "generally_available_models" {
  access_group_name = "generally-available-models"

  # distinct(): a model can have both a provider-specific and a shared-alias deployment.
  access_model_names = distinct(concat(
    [
      for key in sort(keys(litellm_model.amazon_bedrock)) :
      litellm_model.amazon_bedrock[key].model_name
      if try(local.ai_gateway_models_filtered.amazon_bedrock[key].generally_available, false)
    ],
    [
      for key in sort(keys(litellm_model.google_gemini_enterprise_agent_platform)) :
      litellm_model.google_gemini_enterprise_agent_platform[key].model_name
      if try(local.ai_gateway_models_filtered.google_gemini_enterprise_agent_platform[key].generally_available, false)
    ],
    [
      for key in sort(keys(litellm_model.microsoft_foundry)) :
      litellm_model.microsoft_foundry[key].model_name
      if try(local.ai_gateway_models_filtered.microsoft_foundry[key].generally_available, false)
    ],
    [
      for key in sort(keys(litellm_model.amazon_bedrock_shared)) :
      litellm_model.amazon_bedrock_shared[key].model_name
      if try(local.ai_gateway_models_filtered.amazon_bedrock[key].generally_available, false)
    ],
    [
      for key in sort(keys(litellm_model.microsoft_foundry_shared)) :
      litellm_model.microsoft_foundry_shared[key].model_name
      if try(local.ai_gateway_models_filtered.microsoft_foundry[key].generally_available, false)
    ]
  ))
}
