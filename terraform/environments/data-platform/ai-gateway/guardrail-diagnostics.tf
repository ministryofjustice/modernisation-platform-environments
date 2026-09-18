ephemeral "random_password" "guardrail_diagnostics_key" {
  count = local.guardrail_diagnostics_enabled ? 1 : 0

  length  = 40
  special = false
}

module "litellm_guardrail_diagnostics_key_secret" {
  source = "git::https://github.com/terraform-aws-modules/terraform-aws-secrets-manager.git?ref=d03382d3ec9c12b849fbbe35b770eaa047f7bbea" # v2.1.0

  create = local.guardrail_diagnostics_enabled

  name                    = "${local.component_name}/guardrail-diagnostics-key"
  description             = "Temporary LiteLLM key for guardrail diagnostics"
  kms_key_id              = local.guardrail_diagnostics_enabled ? module.ai_gateway_guardrail_diagnostics_kms_key[0].key_arn : null
  recovery_window_in_days = 0

  secret_string_wo         = local.guardrail_diagnostics_key
  secret_string_wo_version = tostring(var.guardrail_diagnostics_key_version)
}

resource "litellm_key" "guardrail_diagnostics" {
  count = local.guardrail_diagnostics_enabled ? 1 : 0

  key_wo         = local.guardrail_diagnostics_key
  key_wo_version = tostring(var.guardrail_diagnostics_key_version)
  key_alias      = "guardrail-diagnostics"
  duration       = "${var.guardrail_diagnostics_retention_days}d"

  models = concat(
    [for model in values(litellm_model.amazon_bedrock) : model.model_name],
    [for model in values(litellm_model.google_gemini_enterprise_agent_platform) : model.model_name],
    [for model in values(litellm_model.microsoft_foundry) : model.model_name]
  )

  allowed_routes        = ["llm_api_routes"]
  max_parallel_requests = 2
  rpm_limit             = 10

  metadata = {
    purpose = "Temporary guardrail diagnostics"
    logging = jsonencode([
      {
        callback_name = "s3_v2"
        callback_type = "failure"
        callback_vars = {}
      }
    ])
  }

  depends_on = [helm_release.litellm_guardrail_diagnostics]
}
