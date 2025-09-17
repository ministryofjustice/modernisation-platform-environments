resource "kubernetes_manifest" "dashboard_service_app_secrets_secret" {
  #checkov:skip=CKV_SECRET_6:secretKey is a reference to the key in the secret

  count = terraform.workspace == "analytical-platform-compute-test" ? 0 : 1

  manifest = {
    "apiVersion" = "external-secrets.io/v1"
    "kind"       = "ExternalSecret"
    "metadata" = {
      "name"      = "dashboard-service-app-secrets"
      "namespace" = kubernetes_namespace.dashboard_service[0].metadata[0].name
    }
    "spec" = {
      "refreshInterval" = "1m"
      "secretStoreRef" = {
        "kind" = "ClusterSecretStore"
        "name" = "aws-secretsmanager"
      }
      "target" = {
        "name" = "dashboard-service-app-secrets"
      }
      "data" = [
        {
          "remoteRef" = {
            "key"      = tostring(module.dashboard_service_app_secrets[0].secret_id)
            "property" = "secret_key"
          }
          "secretKey" = "secret-key"
        },
        {
          "remoteRef" = {
            "key"      = tostring(module.dashboard_service_app_secrets[0].secret_id)
            "property" = "sentry_dsn"
          }
          "secretKey" = "sentry-dsn"
        },
        {
          "remoteRef" = {
            "key"      = tostring(module.dashboard_service_app_secrets[0].secret_id)
            "property" = "auth0_client_id"
          }
          "secretKey" = "auth0-client-id" #checkov:skip=CKV_SECRET_6:secretKey is a reference to the key in the secret
        },
        {
          "remoteRef" = {
            "key"              = tostring(module.dashboard_service_app_secrets[0].secret_id)
            "property"         = "auth0_client_secret"
            "decodingStrategy" = "Base64"
          }
          "secretKey" = "auth0-client-secret" #checkov:skip=CKV_SECRET_6:secretKey is a reference to the key in the secret
        },
      ]
    }
  }
}
