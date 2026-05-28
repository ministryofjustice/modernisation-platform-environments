resource "kubernetes_service_account_v1" "litellm" {
  depends_on = [kubernetes_namespace_v1.ai_gateway]

  metadata {
    name      = "litellm"
    namespace = local.component_name

    annotations = {
      "eks.amazonaws.com/role-arn" = module.iam_role.arn
    }
  }
}
