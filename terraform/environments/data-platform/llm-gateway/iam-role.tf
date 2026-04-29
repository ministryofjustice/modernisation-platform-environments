module "iam_role" {
  source = "git::https://github.com/terraform-aws-modules/terraform-aws-iam.git//modules/iam-role-for-service-accounts?ref=277e8947b1267290988e47882d8dc116850929be" # v6.4.0

  name = local.component_name

  oidc_providers = {
    main = {
      provider_arn               = data.aws_iam_openid_connect_provider.cluster.arn
      namespace_service_accounts = ["llm-gateway:litellm"]
    }
  }

  inline_policy_statements = [
    {
      sid    = "AwsMarketplaceAccess"
      effect = "Allow"
      actions = [
        "aws-marketplace:Subscribe",
        "aws-marketplace:ViewSubscriptions"
      ]
      resources = ["*"]
    },
    {
      sid       = "BedrockInferenceProfileAccess"
      effect    = "Allow"
      actions   = ["bedrock:InvokeModel*"]
      resources = formatlist("arn:aws:bedrock:%s:${data.aws_caller_identity.current.account_id}:inference-profile/*", ["eu-west-1", "eu-west-2"])
    },
    {
      sid       = "BedrockFoundationModelAccess"
      effect    = "Allow"
      actions   = ["bedrock:InvokeModel*"]
      resources = ["arn:aws:bedrock:*::foundation-model/*"]
    }
  ]
}
