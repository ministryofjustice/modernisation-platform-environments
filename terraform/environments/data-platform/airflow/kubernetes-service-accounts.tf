# Used by the External Secrets operator (via the SecretStore below) to read
# Airflow workflow secrets from analytical-platform-data-production. The role
# is created in analytical-platform/terraform/aws/analytical-platform-data-production/airflow-service
# and trusts mwaa:external-secrets-analytical-platform-data-production on this cluster.
resource "kubernetes_service_account_v1" "mwaa_external_secrets_analytical_platform_data_production" {
  metadata {
    namespace = kubernetes_namespace_v1.mwaa.metadata[0].name
    name      = "external-secrets-analytical-platform-data-production"
    annotations = {
      "eks.amazonaws.com/role-arn" = "arn:aws:iam::${local.environment_management.account_ids["analytical-platform-data-production"]}:role/${local.application_name}-${local.environment}-external-secrets"
    }
  }
}
