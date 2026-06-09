module "iam_role" {
  source = "git::https://github.com/terraform-aws-modules/terraform-aws-iam.git//modules/iam-role-for-service-accounts?ref=5b962b1163790398605f2b17447cf5b6cc512237" # v6.6.1

  name = local.component_name

  policies = {
    ai-gateway = module.ai_gateway_iam_policy.arn
  }

  oidc_providers = {
    main = {
      provider_arn               = data.aws_iam_openid_connect_provider.cluster.arn
      namespace_service_accounts = ["${local.component_name}:${local.component_name}"]
    }
  }
}
