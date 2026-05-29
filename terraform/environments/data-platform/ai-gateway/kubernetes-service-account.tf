resource "kubernetes_service_account_v1" "ai_gateway" {
  metadata {
    name      = local.component_name
    namespace = module.ai_gateway_namespace.name

    annotations = {
      "eks.amazonaws.com/role-arn" = module.iam_role.arn
    }
  }
}
