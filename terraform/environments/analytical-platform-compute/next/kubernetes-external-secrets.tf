resource "kubernetes_manifest" "azure_secrets" {
  #checkov:skip=CKV_SECRET_6:secretKey is a reference to the key in the secret

  count = terraform.workspace == "analytical-platform-compute-development" ? 1 : 0

  manifest = {
    "apiVersion" = "external-secrets.io/v1"
    "kind"       = "ExternalSecret"
    "metadata" = {
      "name"      = "azure"
      "namespace" = kubernetes_namespace.main[0].metadata[0].name
    }
    "spec" = {
      "secretStoreRef" = {
        "kind" = "ClusterSecretStore"
        "name" = "aws-secretsmanager"
      }
      "target" = {
        "name" = "azure"
      }
      "data" = [
        {
          "remoteRef" = {
            "key"      = tostring(module.azure_secrets[0].secret_id)
            "property" = "client_id"
          }
          "secretKey" = "client-id"
        },
        {
          "remoteRef" = {
            "key"      = tostring(module.azure_secrets[0].secret_id)
            "property" = "client_secret"
          }
          "secretKey" = "client-secret" #checkov:skip=CKV_SECRET_6:secretKey is a reference to the key in the secret
        },
        {
          "remoteRef" = {
            "key"      = tostring(module.azure_secrets[0].secret_id)
            "property" = "tenant_id"
          }
          "secretKey" = "tenant-id"
        },
      ]
    }
  }
}
