resource "litellm_guardrail" "prompt_attack" {
  guardrail_name = "${local.component_name}-prompt-attack"
  guardrail      = "bedrock"
  mode           = "pre_call"
  default_on     = false

  litellm_params = jsonencode({
    guardrailIdentifier = aws_bedrock_guardrail.prompt_attack.guardrail_id
    guardrailVersion    = aws_bedrock_guardrail_version.prompt_attack.version
  })
}
