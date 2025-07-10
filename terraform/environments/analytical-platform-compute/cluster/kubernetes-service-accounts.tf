resource "kubernetes_service_account" "mwaa_external_secrets_analytical_platform_data_production" {
  metadata {
    namespace = kubernetes_namespace.mwaa.metadata[0].name
    # namespace = data.kubernetes_namespace.mwaa.metadata[0].name
    name = "external-secrets-analytical-platform-data-production"
    annotations = {
      "eks.amazonaws.com/role-arn" = "arn:aws:iam::${local.environment_management.account_ids["analytical-platform-data-production"]}:role/mojap-compute-${local.environment}-external-secrets"
    }
  }
}
