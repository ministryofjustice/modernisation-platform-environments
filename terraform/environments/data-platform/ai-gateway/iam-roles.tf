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
