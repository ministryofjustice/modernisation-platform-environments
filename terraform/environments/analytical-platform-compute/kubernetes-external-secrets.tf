resource "kubernetes_manifest" "ui_sentry_dsn_external_secret" {
  #checkov:skip=CKV_SECRET_6:secretKey is a reference to the key in the secret

  manifest = {
    "apiVersion" = "external-secrets.io/v1beta1"
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
            "key" = module.ui_sentry_dsn_secret.secret_id
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
    "apiVersion" = "external-secrets.io/v1beta1"
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
            "key" = module.ui_azure_client_secret.secret_id
          }
          "secretKey" = "client-id"
        },
        {
          "remoteRef" = {
            "key" = module.ui_azure_tenant_secret.secret_id
          }
          "secretKey" = "tenant-id"
        },
      ]
    }
  }
}

resource "kubernetes_manifest" "dashboard_service_app_secrets_secret" {
  #checkov:skip=CKV_SECRET_6:secretKey is a reference to the key in the secret

  count = terraform.workspace == "analytical-platform-compute-test" ? 0 : 1

  manifest = {
    "apiVersion" = "external-secrets.io/v1beta1"
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
            "key"      = module.dashboard_service_app_secrets[0].secret_id
            "property" = "secret_key"
          }
          "secretKey" = "secret-key"
        },
        {
          "remoteRef" = {
            "key"      = module.dashboard_service_app_secrets[0].secret_id
            "property" = "sentry_dsn"
          }
          "secretKey" = "sentry-dsn"
        },
        {
          "remoteRef" = {
            "key"      = module.dashboard_service_app_secrets[0].secret_id
            "property" = "auth0_client_id"
          }
          "secretKey" = "auth0-client-id" #checkov:skip=CKV_SECRET_6:secretKey is a reference to the key in the secret
        },
        {
          "remoteRef" = {
            "key"              = module.dashboard_service_app_secrets[0].secret_id
            "property"         = "auth0_client_secret"
            "decodingStrategy" = "Base64"
          }
          "secretKey" = "auth0-client-secret" #checkov:skip=CKV_SECRET_6:secretKey is a reference to the key in the secret
        },
      ]
    }
  }
}
