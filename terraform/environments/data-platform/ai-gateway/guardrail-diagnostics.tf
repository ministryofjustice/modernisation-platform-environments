resource "aws_secretsmanager_secret" "guardrail_diagnostics_key" {
  count = var.guardrail_diagnostics_enabled ? 1 : 0

  #checkov:skip=CKV2_AWS_57: Rotation uses the write-only version nonce and disabling diagnostics destroys the temporary secret
  name                    = "${local.component_name}/guardrail-diagnostics-key"
  description             = "Temporary LiteLLM key for guardrail diagnostics"
  kms_key_id              = module.ai_gateway_guardrail_diagnostics_kms_key[0].key_arn
  recovery_window_in_days = 0
}

resource "aws_secretsmanager_secret_version" "guardrail_diagnostics_key" {
  count = var.guardrail_diagnostics_enabled ? 1 : 0

  secret_id                = aws_secretsmanager_secret.guardrail_diagnostics_key[0].id
  secret_string_wo         = var.guardrail_diagnostics_key
  secret_string_wo_version = var.guardrail_diagnostics_key_version
}

resource "litellm_key" "guardrail_diagnostics" {
  count = var.guardrail_diagnostics_enabled ? 1 : 0

  key_wo         = var.guardrail_diagnostics_key
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

  depends_on = [helm_release.litellm]
}