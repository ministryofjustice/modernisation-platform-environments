resource "kubernetes_manifest" "ui_sentry_dsn_external_secret" {
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

resource "kubernetes_manifest" "actions_runners_github_app_secret" {
  count = terraform.workspace == "analytical-platform-compute-production" ? 1 : 0

  manifest = {
    "apiVersion" = "external-secrets.io/v1beta1"
    "kind"       = "ExternalSecret"
    "metadata" = {
      "name"      = "actions-runner-github-app"
      "namespace" = kubernetes_namespace.actions_runners[0].metadata[0].name
    }
    "spec" = {
      "refreshInterval" = "1m"
      "secretStoreRef" = {
        "kind" = "ClusterSecretStore"
        "name" = "aws-secretsmanager"
      }
      "target" = {
        "name" = "actions-runner-github-app"
      }
      "data" = [
        {
          "remoteRef" = {
            "key"      = module.actions_runners_github_app_secret[0].secret_id
            "property" = "app_id"
          }
          "secretKey" = "app-id"
        },
        {
          "remoteRef" = {
            "key"      = module.actions_runners_github_app_secret[0].secret_id
            "property" = "app_key"
          }
          "secretKey" = "app-key"
        },
        {
          "remoteRef" = {
            "key"      = module.actions_runners_github_app_secret[0].secret_id
            "property" = "client_id"
          }
          "secretKey" = "client-id"
        },
        {
          "remoteRef" = {
            "key"      = module.actions_runners_github_app_secret[0].secret_id
            "property" = "installation_id"
          }
          "secretKey" = "installation_id-id"
        },
      ]
    }
  }
}
