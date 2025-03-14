resource "kubernetes_manifest" "secretstore_sample" {
  manifest = {
    "apiVersion" = "external-secrets.io/v1beta1"
    "kind"       = "SecretStore"
    "metadata" = {
      "namespace" = kubernetes_namespace.mwaa.metadata[0].name
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
                "name" = kubernetes_service_account.mwaa_external_secrets_analytical_platform_data_production.metadata[0].name
              }
            }
          }
        }
      }
    }
  }
}
