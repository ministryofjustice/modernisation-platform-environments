# SecretStore referenced by every workflow ExternalSecret created by
# analytical-platform-airflow (secretStoreRefName: analytical-platform-data-production).
resource "kubernetes_manifest" "eso_secretstore_data_production" {
  manifest = {
    "apiVersion" = "external-secrets.io/v1"
    "kind"       = "SecretStore"
    "metadata" = {
      "namespace" = kubernetes_namespace_v1.mwaa.metadata[0].name
      "name"      = "analytical-platform-data-production"
    }
    "spec" = {
      "provider" = {
        "aws" = {
          "service" = "SecretsManager"
          "region"  = "eu-west-2"
          "auth" = {
            "jwt" = {
              "serviceAccountRef" = {
                "name" = kubernetes_service_account_v1.mwaa_external_secrets_analytical_platform_data_production.metadata[0].name
              }
            }
          }
        }
      }
    }
  }
}
