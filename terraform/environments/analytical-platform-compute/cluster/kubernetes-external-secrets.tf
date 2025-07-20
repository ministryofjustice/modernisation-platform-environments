resource "kubernetes_manifest" "ui_sentry_dsn_external_secret" {
  #checkov:skip=CKV_SECRET_6:secretKey is a reference to the key in the secret

  manifest = {
    "apiVersion" = "external-secrets.io/v1"
    "kind"       = "ExternalSecret"
    "metadata" = {
      "name"      = "ui-sentry-dsn"
      "namespace" = kubernetes_namespace.ui.metadata[0].name
    }
    "spec" = {
      "secretStoreRef" = {
        "kind" = "ClusterSecretStore"
        "name" = "aws-secretsmanager"
      }
      "target" = {
        "name" = "ui-sentry-dsn"
      }
      "data" = [
        {
          "remoteRef" = {
            "key" = tostring(module.ui_sentry_dsn_secret.secret_id)
          }
          "secretKey" = "dsn"
        },
      ]
    }
  }
}

resource "kubernetes_manifest" "ui_azure_external_secret" {
  #checkov:skip=CKV_SECRET_6:secretKey is a reference to the key in the secret

  manifest = {
    "apiVersion" = "external-secrets.io/v1"
    "kind"       = "ExternalSecret"
    "metadata" = {
      "name"      = "ui-azure-secrets"
      "namespace" = kubernetes_namespace.ui.metadata[0].name
    }
    "spec" = {
      "secretStoreRef" = {
        "kind" = "ClusterSecretStore"
        "name" = "aws-secretsmanager"
      }
      "target" = {
        "name" = "ui-azure-secrets"
      }
      "data" = [
        {
          "remoteRef" = {
            "key" = tostring(module.ui_azure_client_secret.secret_id)
          }
          "secretKey" = "client-id"
        },
        {
          "remoteRef" = {
            "key" = tostring(module.ui_azure_tenant_secret.secret_id)
          }
          "secretKey" = "tenant-id"
        },
      ]
    }
  }
}
