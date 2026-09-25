variable "sip_delivery_assistant_bedrock_guardrail_arn" {
  description = "Optional approved sprinkler Bedrock guardrail ARN. Leave null to disable guardrail access."
  type        = string
  default     = null
  nullable    = true

  validation {
    condition = (
      var.sip_delivery_assistant_bedrock_guardrail_arn == null ||
      can(regex(
        "^arn:aws:bedrock:eu-west-2:348456244381:guardrail/[A-Za-z0-9-]+$",
        var.sip_delivery_assistant_bedrock_guardrail_arn
      ))
    )
    error_message = "The guardrail ARN must identify one guardrail in sprinkler account 348456244381 in eu-west-2."
  }
}

locals {
  sip_delivery_assistant_bedrock_inference_profile_id = "eu.anthropic.claude-sonnet-4-5-20250929-v1:0"
  sip_delivery_assistant_bedrock_model_arns = toset([
    for model in data.aws_bedrock_inference_profile.sip_delivery_assistant.models : model.model_arn
  ])
}

data "aws_bedrock_inference_profile" "sip_delivery_assistant" {
  inference_profile_id = local.sip_delivery_assistant_bedrock_inference_profile_id

  lifecycle {
    postcondition {
      condition     = self.status == "ACTIVE" && self.type == "SYSTEM_DEFINED"
      error_message = "The SIP Delivery Assistant requires the active system-defined EU inference profile."
    }

    postcondition {
      condition = can(regex(
        "^arn:aws:bedrock:eu-west-2:348456244381:inference-profile/eu\\.anthropic\\.claude-sonnet-4-5-20250929-v1:0$",
        self.inference_profile_arn
      ))
      error_message = "The resolved inference profile does not match the approved eu-west-2 EU Claude Sonnet 4.5 profile."
    }

    postcondition {
      condition = length(self.models) > 0 && alltrue([
        for model in self.models : can(regex(
          "^arn:aws:bedrock:eu-[a-z]+-[1-9]::foundation-model/anthropic\\.claude-sonnet-4-5-20250929-v1:0$",
          model.model_arn
        ))
      ])
      error_message = "The EU inference profile must resolve only to exact EU-region Claude Sonnet 4.5 foundation models."
    }
  }
}

data "aws_iam_policy_document" "sip_delivery_assistant_bedrock_assume_role" {
  #checkov:skip=CKV_AWS_358:This repository uses GitHub immutable OIDC subjects; owner ID 2203574 and repository ID 1373350473 bind the identity, the subject is restricted to the sip-generation environment, and the audience remains exactly sts.amazonaws.com; this is a Checkov compatibility false positive.
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRoleWithWebIdentity"]

    principals {
      type        = "Federated"
      identifiers = ["arn:aws:iam::348456244381:oidc-provider/token.actions.githubusercontent.com"]
    }

    condition {
      test     = "StringEquals"
      variable = "token.actions.githubusercontent.com:aud"
      values   = ["sts.amazonaws.com"]
    }

    condition {
      test     = "StringEquals"
      variable = "token.actions.githubusercontent.com:sub"
      values   = ["repo:ministryofjustice@2203574/modernisation-platform-sip-delivery-assistant@1373350473:environment:sip-generation"]
    }
  }
}

resource "aws_iam_role" "sip_delivery_assistant_bedrock" {
  name               = "modernisation-platform-sip-delivery-assistant-bedrock"
  assume_role_policy = data.aws_iam_policy_document.sip_delivery_assistant_bedrock_assume_role.json
  tags               = local.tags

  lifecycle {
    precondition {
      condition     = data.aws_caller_identity.current.account_id == "348456244381"
      error_message = "The SIP Delivery Assistant Bedrock role may be created only in sprinkler account 348456244381."
    }
  }
}

data "aws_iam_policy_document" "sip_delivery_assistant_bedrock" {
  statement {
    sid     = "InvokeApprovedInferenceProfile"
    effect  = "Allow"
    actions = ["bedrock:InvokeModel"]
    resources = [
      data.aws_bedrock_inference_profile.sip_delivery_assistant.inference_profile_arn
    ]
  }

  statement {
    sid       = "InvokeApprovedModelThroughProfile"
    effect    = "Allow"
    actions   = ["bedrock:InvokeModel"]
    resources = sort(tolist(local.sip_delivery_assistant_bedrock_model_arns))

    condition {
      test     = "StringEquals"
      variable = "bedrock:InferenceProfileArn"
      values = [
        data.aws_bedrock_inference_profile.sip_delivery_assistant.inference_profile_arn
      ]
    }
  }

  dynamic "statement" {
    for_each = var.sip_delivery_assistant_bedrock_guardrail_arn == null ? [] : [var.sip_delivery_assistant_bedrock_guardrail_arn]

    content {
      sid       = "ApplyApprovedGuardrail"
      effect    = "Allow"
      actions   = ["bedrock:ApplyGuardrail"]
      resources = [statement.value]
    }
  }
}

resource "aws_iam_policy" "sip_delivery_assistant_bedrock" {
  name        = "modernisation-platform-sip-delivery-assistant-bedrock"
  description = "Permits the SIP Delivery Assistant to invoke only the approved Bedrock model resources"
  policy      = data.aws_iam_policy_document.sip_delivery_assistant_bedrock.json
  tags        = local.tags
}

resource "aws_iam_role_policy_attachment" "sip_delivery_assistant_bedrock" {
  role       = aws_iam_role.sip_delivery_assistant_bedrock.name
  policy_arn = aws_iam_policy.sip_delivery_assistant_bedrock.arn
}

output "sip_delivery_assistant_bedrock_role_arn" {
  description = "Configure this non-secret ARN as SIP_BEDROCK_ROLE_ARN in the delivery assistant's sip-generation GitHub Environment."
  value       = aws_iam_role.sip_delivery_assistant_bedrock.arn
}

output "sip_delivery_assistant_bedrock_inference_profile" {
  description = "Approved geography-bound EU inference profile and AWS-resolved EU foundation-model ARNs; inference remains within the profile's fixed EU destination set."
  value = {
    id                    = local.sip_delivery_assistant_bedrock_inference_profile_id
    arn                   = data.aws_bedrock_inference_profile.sip_delivery_assistant.inference_profile_arn
    foundation_model_arns = sort(tolist(local.sip_delivery_assistant_bedrock_model_arns))
  }
}
