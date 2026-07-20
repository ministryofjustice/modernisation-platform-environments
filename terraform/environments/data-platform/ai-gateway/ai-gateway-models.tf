resource "litellm_model" "amazon_bedrock" {
  for_each            = tomap(local.ai_gateway_models.amazon_bedrock)
  custom_llm_provider = "bedrock"
  model_name          = "bedrock-${each.key}"
  base_model          = each.value.model_id
  tier                = "paid"

  aws_region_name = each.value.region
  aws_role_name   = try(each.value.role_name, module.iam_role.arn)

  additional_litellm_params = {
    ai_model_provider            = "Amazon Bedrock"
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
  for_each            = tomap(local.ai_gateway_models.google_gemini_enterprise_agent_platform)
  custom_llm_provider = "gemini"
  model_name          = "gemini-${each.key}"
  base_model          = each.value.model_id
  tier                = "paid"

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
  for_each            = tomap(local.ai_gateway_models.microsoft_foundry)
  custom_llm_provider = "azure"
  model_name          = "azure-${each.key}"
  base_model          = each.value.model_id
  tier                = "paid"

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
