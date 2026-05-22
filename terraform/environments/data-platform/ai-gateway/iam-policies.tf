data "aws_iam_policy_document" "ai_gateway" {
  statement {
    sid    = "AwsMarketplaceAccess"
    effect = "Allow"
    actions = [
      "aws-marketplace:Subscribe",
      "aws-marketplace:ViewSubscriptions"
    ]
    resources = ["*"]
  }

  statement {
    sid       = "BedrockInferenceProfileAccess"
    effect    = "Allow"
    actions   = ["bedrock:InvokeModel*"]
    resources = formatlist("arn:aws:bedrock:%s:${data.aws_caller_identity.current.account_id}:inference-profile/*", ["eu-west-1", "eu-west-2"])
  }

  statement {
    sid       = "BedrockFoundationModelAccess"
    effect    = "Allow"
    actions   = ["bedrock:InvokeModel*"]
    resources = ["arn:aws:bedrock:*::foundation-model/*"]
  }

  statement {
    sid    = "DenyClaudeCodeCLI"
    effect = "Deny"
    actions = [
      "bedrock:InvokeModel",
      "bedrock:InvokeModelWithResponseStream"
    ]
    resources = ["*"]
    condition {
      test     = "StringLike"
      variable = "aws:UserAgent"
      values = [
        "claude-cli*",
        "claude-cli/*"
      ]
    }
  }
}

module "ai_gateway_iam_policy" {
  source = "git::https://github.com/terraform-aws-modules/terraform-aws-iam.git//modules/iam-policy?ref=1d73bcb359419e1b41872ac5ccaf8808b8f1150e" # v6.6.0

  name_prefix = "ai-gateway"

  policy = data.aws_iam_policy_document.ai_gateway.json
}
