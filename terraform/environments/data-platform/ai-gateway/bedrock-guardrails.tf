resource "aws_bedrock_guardrail" "prompt_attack" {
  name                      = "${local.component_name}-prompt-attack"
  blocked_input_messaging   = "Your request was blocked by an AI Gateway security policy, please contact #ask-data-platform for assistance."
  blocked_outputs_messaging = "The response was blocked by an AI Gateway security policy, please contact #ask-data-platform for assistance."

  cross_region_config {
    guardrail_profile_identifier = "arn:aws:bedrock:${data.aws_region.current.region}:${data.aws_caller_identity.current.account_id}:guardrail-profile/uk.guardrail.v1:0"
  }

  content_policy_config {
    tier_config {
      tier_name = "STANDARD"
    }

    filters_config {
      type            = "PROMPT_ATTACK"
      input_enabled   = true
      input_action    = "BLOCK"
      input_strength  = "HIGH"
      output_enabled  = false
      output_strength = "NONE"
    }
  }
}

resource "aws_bedrock_guardrail_version" "prompt_attack" {
  description   = "Prompt-attack policy for the AI Gateway"
  guardrail_arn = aws_bedrock_guardrail.prompt_attack.guardrail_arn
  skip_destroy  = true
}
