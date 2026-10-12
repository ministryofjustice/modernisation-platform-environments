resource "kubernetes_service_account_v1" "openai" {
  count = local.openai_enabled ? 1 : 0

  metadata {
    name      = "${local.component_name}-openai"
    namespace = module.ai_gateway_namespace.name

    annotations = {
      "eks.amazonaws.com/role-arn" = module.openai_iam_role[0].arn
    }
  }
}

resource "kubernetes_service_account_v1" "ai_gateway" {
  metadata {
    name      = local.component_name
    namespace = module.ai_gateway_namespace.name

    annotations = {
      "eks.amazonaws.com/role-arn" = module.iam_role.arn
    }
  }
}
