module "iam_role" {
  count = terraform.workspace == "data-platform-development" ? 1 : 0

  source = "git::https://github.com/terraform-aws-modules/terraform-aws-iam.git//modules/iam-role?ref=dc7a9f3bed20aaaba05d151b0789745070424b3a" # v6.2.1

  name            = local.component_name
  use_name_prefix = false

  trust_policy_permissions = {
    TrustedRoles = {
      actions = ["sts:AssumeRole"]
      principals = [{
        type        = "AWS"
        identifiers = [data.kubernetes_secret.irsa[0].data["role_arn"]]
      }]
    }
  }

  create_inline_policy = true

  inline_policy_permissions = {
    # BedrockInferenceProfileAccess = {
    #   effect = "Allow"
    #   actions = [
    #     "bedrock:Converse",
    #     "bedrock:ConverseStream",
    #     "bedrock:InvokeModel",
    #     "bedrock:InvokeModelWithBidirectionalStream",
    #     "bedrock:InvokeModelWithResponseStream"
    #   ]
    #   resources = [for profile in aws_bedrock_inference_profile.main : profile.arn]
    # }
    BedrockInferenceProfileAccess = {
      effect    = "Allow"
      actions   = ["bedrock:InvokeModel*"]
      resources = formatlist("arn:aws:bedrock:%s:${data.aws_caller_identity.current.account_id}:inference-profile/*", ["eu-west-1", "eu-west-2"])
    }
    BedrockFoundationModelAccess = {
      effect    = "Allow"
      actions   = ["bedrock:InvokeModel*"]
      resources = ["arn:aws:bedrock:*::foundation-model/*"]
    }
  }
}
