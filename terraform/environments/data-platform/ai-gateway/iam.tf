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
}

module "ai_gateway_iam_policy" {
  source = "git::https://github.com/terraform-aws-modules/terraform-aws-iam.git//modules/iam-policy?ref=277e8947b1267290988e47882d8dc116850929be" # v6.4.0

  name_prefix = "ai-gateway"

  policy = data.aws_iam_policy_document.ai_gateway.json
}

module "iam_role" {
  source = "git::https://github.com/terraform-aws-modules/terraform-aws-iam.git//modules/iam-role-for-service-accounts?ref=277e8947b1267290988e47882d8dc116850929be" # v6.4.0

  name = local.component_name

  policies = {
    ai-gateway = module.ai_gateway_iam_policy.arn
  }

  oidc_providers = {
    main = {
      provider_arn               = data.aws_iam_openid_connect_provider.cluster.arn
      namespace_service_accounts = ["ai-gateway:litellm"]
    }
  }
}
