resource "litellm_model" "amazon_bedrock" {
  for_each = try(local.ai_gateway_models_filtered.amazon_bedrock, {})

  custom_llm_provider = "bedrock"
  model_name          = try(each.value.shared_model_name, "bedrock-${each.key}")
  base_model          = each.value.model_id
  tier                = "paid"

  aws_region_name = each.value.region
  aws_role_name   = can(each.value.aws_role_name) ? "arn:aws:iam::${local.environment_management.account_ids[each.value.aws_account_name]}:role/${each.value.aws_role_name}" : module.iam_role.arn

  additional_litellm_params = {
    ai_model_provider            = try(each.value.model_provider, "Amazon Bedrock")
    ai_model_family              = each.value.model_family
    ai_model_name                = each.value.model_name
    ai_model_generally_available = each.value.generally_available
    additional_drop_params       = "[\"ai_model_provider\",\"ai_model_family\",\"ai_model_name\",\"ai_model_generally_available\"]"
  }

  depends_on = [
    helm_release.ai_gateway_configuration,
    helm_release.litellm,
    helm_release.litellm_admin
  ]
}

resource "litellm_model" "google_gemini_enterprise_agent_platform" {
  for_each = try(local.ai_gateway_models_filtered.google_gemini_enterprise_agent_platform, {})

  custom_llm_provider = "vertex_ai"
  model_name          = startswith(each.key, "gemini-") ? each.key : "gemini-${each.key}"
  base_model          = each.value.model_id
  tier                = "paid"

  # vertex_credentials is deliberately omitted; the pod's GOOGLE_APPLICATION_CREDENTIALS (WIF) is used instead
  # "eu" is a multi-region identifier, not a regional location, so it's routed via api_base rather than vertex_location
  vertex_project  = local.google_cloud_project_name
  vertex_location = each.value.location == "eu" ? null : each.value.location
  model_api_base  = each.value.location == "eu" ? "https://aiplatform.eu.rep.googleapis.com" : null

  additional_litellm_params = {
    ai_model_provider            = "Google Gemini Enterprise Agent Platform"
    ai_model_family              = each.value.model_family
    ai_model_name                = each.value.model_name
    ai_model_generally_available = each.value.generally_available
    additional_drop_params       = "[\"ai_model_provider\",\"ai_model_family\",\"ai_model_name\",\"ai_model_generally_available\"]"
  }

  depends_on = [
    helm_release.ai_gateway_configuration,
    helm_release.litellm,
    helm_release.litellm_admin
  ]
}

resource "litellm_model" "microsoft_foundry" {
  for_each = try(local.ai_gateway_models_filtered.microsoft_foundry, {})

  custom_llm_provider = each.value.model_provider
  model_name          = try(each.value.shared_model_name, "azure-${each.key}")
  base_model          = each.value.model_id
  tier                = "paid"

  model_api_base = can(each.value.model_endpoint) ? "${jsondecode(data.aws_secretsmanager_secret_version.microsoft_foundry_jedi_gateway.secret_string)["endpoint"]}/${each.value.model_endpoint}" : jsondecode(data.aws_secretsmanager_secret_version.microsoft_foundry_jedi_gateway.secret_string)["endpoint"]
  api_version    = try(each.value.model_api_version, each.value.model_provider == "azure" ? "v1" : null)

  additional_litellm_params = {
    ai_model_provider            = "Microsoft Foundry"
    ai_model_family              = each.value.model_family
    ai_model_name                = each.value.model_name
    ai_model_generally_available = each.value.generally_available
    additional_drop_params       = "[\"ai_model_provider\",\"ai_model_family\",\"ai_model_name\",\"ai_model_generally_available\"]"
  }

  depends_on = [
    helm_release.ai_gateway_configuration,
    helm_release.litellm,
    helm_release.litellm_admin
  ]
}
