module "iam_role" {
  source = "git::https://github.com/terraform-aws-modules/terraform-aws-iam.git//modules/iam-role-for-service-accounts?ref=277e8947b1267290988e47882d8dc116850929be" # v6.4.0

  name = local.component_name

  policies = {
    llm-gateway = module.llm_gateway_iam_policy.arn
  }

  oidc_providers = {
    main = {
      provider_arn               = data.aws_iam_openid_connect_provider.cluster.arn
      namespace_service_accounts = ["llm-gateway:litellm"]
    }
  }
}

module "iam_role_cloud_platform" {
  count = terraform.workspace == "data-platform-development" ? 1 : 0

  source = "git::https://github.com/terraform-aws-modules/terraform-aws-iam.git//modules/iam-role?ref=277e8947b1267290988e47882d8dc116850929be" # v6.4.0

  name            = "${local.component_name}-cloud-platform"
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

  policies = {
    llm-gateway = module.llm_gateway_iam_policy.arn
  }
}
