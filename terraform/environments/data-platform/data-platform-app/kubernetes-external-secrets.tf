resource "kubernetes_manifest" "data_platform_app_secrets_secret" {
  #checkov:skip=CKV_SECRET_6:secretKey is a reference to the key in the secret

  count = terraform.workspace == "data-platform-test" ? 0 : 1

  manifest = {
    "apiVersion" = "external-secrets.io/v1"
    "kind"       = "ExternalSecret"
    "metadata" = {
      "name"      = "data-platform-app-secrets"
      "namespace" = kubernetes_namespace_v1.data_platform_app[0].metadata[0].name
    }
    "spec" = {
      "refreshInterval" = "1m"
      "secretStoreRef" = {
        "kind" = "ClusterSecretStore"
        "name" = "aws-secretsmanager"
      }
      "target" = {
        "name" = "data-platform-app-secrets"
      }
      "data" = [
        {
          "remoteRef" = {
            "key"      = tostring(module.data_platform_app_secrets[0].secret_id)
            "property" = "secret_key"
          }
          "secretKey" = "secret-key"
        },
      ]
    }
  }
}
