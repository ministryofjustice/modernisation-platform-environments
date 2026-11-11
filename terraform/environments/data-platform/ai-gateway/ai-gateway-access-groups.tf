resource "litellm_unified_access_group" "amazon_bedrock" {
  for_each = {
    for model_key, model in try(local.ai_gateway_models_filtered.amazon_bedrock, {}) :
    model_key => model
    if !try(model.generally_available, false)
  }

  access_group_name  = "bedrock-${each.key}"
  access_model_names = [litellm_model.amazon_bedrock[each.key].model_name]
  assigned_team_ids = [
    for team_key, team in local.ai_gateway_configuration.teams : litellm_team.teams[team_key].team_id
    if contains(try(team.unified_access_groups, []), "bedrock-${each.key}")
  ]

  # Teams can be assigned to access groups out-of-band via the LiteLLM UI/API; don't revoke those.
  lifecycle {
    ignore_changes = [assigned_team_ids]
  }
}

resource "litellm_unified_access_group" "amazon_bedrock_batch" {
  for_each = local.ai_gateway_bedrock_batch_models

  access_group_name  = "bedrock-batch-${each.key}"
  access_model_names = [litellm_model.amazon_bedrock_batch[each.key].model_name]
  assigned_team_ids = [
    for team_key, team in local.ai_gateway_configuration.teams : litellm_team.teams[team_key].team_id
    if contains(try(team.unified_access_groups, []), "bedrock-batch-${each.key}")
  ]

  # Teams can be assigned to access groups out-of-band via the LiteLLM UI/API; don't revoke those.
  lifecycle {
    ignore_changes = [assigned_team_ids]
  }
}

resource "litellm_unified_access_group" "google_gemini_enterprise_agent_platform" {
  for_each = try(local.ai_gateway_models_filtered.google_gemini_enterprise_agent_platform, {})

  access_group_name  = "gemini-${each.key}"
  access_model_names = [litellm_model.google_gemini_enterprise_agent_platform[each.key].model_name]
  assigned_team_ids = [
    for team_key, team in local.ai_gateway_configuration.teams : litellm_team.teams[team_key].team_id
    if contains(try(team.unified_access_groups, []), "gemini-${each.key}")
  ]

  # Teams can be assigned to access groups out-of-band via the LiteLLM UI/API; don't revoke those.
  lifecycle {
    ignore_changes = [assigned_team_ids]
  }
}

resource "litellm_unified_access_group" "microsoft_foundry" {
  for_each = try(local.ai_gateway_models_filtered.microsoft_foundry, {})

  access_group_name  = "azure-${each.key}"
  access_model_names = [litellm_model.microsoft_foundry[each.key].model_name]
  assigned_team_ids = [
    for team_key, team in local.ai_gateway_configuration.teams : litellm_team.teams[team_key].team_id
    if contains(try(team.unified_access_groups, []), "azure-${each.key}")
  ]

  # Teams can be assigned to access groups out-of-band via the LiteLLM UI/API; don't revoke those.
  lifecycle {
    ignore_changes = [assigned_team_ids]
  }
}

resource "litellm_unified_access_group" "openai_models" {
  count = length(try(local.ai_gateway_models_filtered.openai, {})) > 0 ? 1 : 0

  access_group_name = "openai-models"
  assigned_team_ids = [
    for team_key, team in local.ai_gateway_configuration.teams : litellm_team.teams[team_key].team_id
    if contains(try(team.unified_access_groups, []), "openai-models")
  ]

  access_model_names = [
    for key in sort(keys(litellm_model.openai)) :
    litellm_model.openai[key].model_name
  ]

  # Teams can be assigned to access groups out-of-band via the LiteLLM UI/API; don't revoke those.
  lifecycle {
    ignore_changes = [assigned_team_ids]

    # Per-model groups are named "openai-<key>", so a model keyed "models" would collide with this group.
    precondition {
      condition     = !contains(keys(local.ai_gateway_models_filtered.openai), "models")
      error_message = "An OpenAI model may not use the key \"models\"; it collides with the \"openai-models\" access group."
    }
  }
}

resource "litellm_unified_access_group" "generally_available_models" {
  access_group_name = "generally-available-models"
  assigned_team_ids = [
    for team_key, team in local.ai_gateway_configuration.teams : litellm_team.teams[team_key].team_id
    if contains(try(team.unified_access_groups, []), "generally-available-models")
  ]

  access_model_names = concat(
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
      for key in sort(keys(litellm_model.openai)) :
      litellm_model.openai[key].model_name
      if try(local.ai_gateway_models_filtered.openai[key].generally_available, false)
    ]
  )

  # Teams can be assigned to access groups out-of-band via the LiteLLM UI/API; don't revoke those.
  lifecycle {
    ignore_changes = [assigned_team_ids]
  }
}
