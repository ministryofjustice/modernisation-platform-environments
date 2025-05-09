resource "aws_bedrock_guardrail" "moj-fl-guardrails-tf" {
  name                      = "moj-familylaw-guardrails-tf"
  blocked_input_messaging   = "Sorry, the model cannot answer this question. Please try another question or visit: https://helpwithchildarrangements.service.justice.gov.uk/ for more information."
  blocked_outputs_messaging = "Sorry, the model cannot answer this question. Please try another question or visit: https://helpwithchildarrangements.service.justice.gov.uk/ for more information."
  description               = "moj-fl-guardrails-tf"

  word_policy_config {
    managed_word_lists_config {
      type = "PROFANITY"
    }
    words_config {
      text = "Anthropic"
    }
    words_config {
      text = "Claude"
    }
    words_config {
      text = "Sonnet"
    }
  }
  contextual_grounding_policy_config {

    filters_config {
      type      = "GROUNDING"
      threshold = 0.9
    }
    filters_config {
      type      = "RELEVANCE"
      threshold = 0.9
    }

  }

  content_policy_config {
    filters_config {
      input_strength  = "HIGH"
      output_strength = "HIGH"
      type            = "HATE"
    }
    filters_config {
      input_strength  = "HIGH"
      output_strength = "HIGH"
      type            = "INSULTS"
    }
    filters_config {
      input_strength  = "LOW"
      output_strength = "HIGH"
      type            = "SEXUAL"
    }
    filters_config {
      input_strength  = "MEDIUM"
      output_strength = "HIGH"
      type            = "VIOLENCE"
    }
    filters_config {
      input_strength  = "LOW"
      output_strength = "HIGH"
      type            = "MISCONDUCT"
    }
  }

  sensitive_information_policy_config {
    pii_entities_config {
      action = "ANONYMIZE"
      type   = "NAME"
    }

  }
}

resource "aws_bedrock_guardrail_version" "moj-fl-guardrails-tf-v1" {
  description   = "v1"
  guardrail_arn = aws_bedrock_guardrail.moj-fl-guardrails-tf.guardrail_arn
  skip_destroy  = true
}