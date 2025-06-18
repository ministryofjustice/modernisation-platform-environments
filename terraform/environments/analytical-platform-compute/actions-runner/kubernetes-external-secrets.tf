resource "kubernetes_manifest" "actions_runners_token_apc_self_hosted_runners_secret" {
  #checkov:skip=CKV_SECRET_6:secretKey is a reference to the key in the secret

  count = terraform.workspace == "analytical-platform-compute-production" ? 1 : 0

  manifest = {
    "apiVersion" = "external-secrets.io/v1"
    "kind"       = "ExternalSecret"
    "metadata" = {
      "name"      = "actions-runners-token-apc-self-hosted-runners"
      "namespace" = kubernetes_namespace.actions_runners[0].metadata[0].name
    }
    "spec" = {
      "refreshInterval" = "1m"
      "secretStoreRef" = {
        "kind" = "ClusterSecretStore"
        "name" = "aws-secretsmanager"
      }
      "target" = {
        "name" = "actions-runners-token-apc-self-hosted-runners"
      }
      "data" = [
        {
          "remoteRef" = {
            "key" = module.actions_runners_token_apc_self_hosted_runners_secret[0].secret_id
          }
          "secretKey" = "token"
        }
      ]
    }
  }
}

resource "kubernetes_manifest" "actions_runners_token_moj_apc_self_hosted_runners_secret" {
  #checkov:skip=CKV_SECRET_6:secretKey is a reference to the key in the secret

  count = terraform.workspace == "analytical-platform-compute-production" ? 1 : 0

  manifest = {
    "apiVersion" = "external-secrets.io/v1"
    "kind"       = "ExternalSecret"
    "metadata" = {
      "name"      = "actions-runners-token-moj-apc-self-hosted-runners"
      "namespace" = kubernetes_namespace.actions_runners[0].metadata[0].name
    }
    "spec" = {
      "refreshInterval" = "1m"
      "secretStoreRef" = {
        "kind" = "ClusterSecretStore"
        "name" = "aws-secretsmanager"
      }
      "target" = {
        "name" = "actions-runners-token-moj-apc-self-hosted-runners"
      }
      "data" = [
        {
          "remoteRef" = {
            "key" = module.actions_runners_token_moj_apc_self_hosted_runners_secret[0].secret_id
          }
          "secretKey" = "token"
        }
      ]
    }
  }
}

resource "kubernetes_manifest" "actions_runners_github_app_apc_self_hosted_runners_secret" {
  #checkov:skip=CKV_SECRET_6:secretKey is a reference to the key in the secret

  count = terraform.workspace == "analytical-platform-compute-production" ? 1 : 0

  manifest = {
    "apiVersion" = "external-secrets.io/v1"
    "kind"       = "ExternalSecret"
    "metadata" = {
      "name"      = "actions-runners-github-app-apc-self-hosted-runners"
      "namespace" = kubernetes_namespace.actions_runners[0].metadata[0].name
    }
    "spec" = {
      "refreshInterval" = "1m"
      "secretStoreRef" = {
        "kind" = "ClusterSecretStore"
        "name" = "aws-secretsmanager"
      }
      "target" = {
        "name" = "actions-runners-github-app-apc-self-hosted-runners"
      }
      "data" = [
        {
          "remoteRef" = {
            "key"      = module.actions_runners_github_app_apc_self_hosted_runners_secret[0].secret_id
            "property" = "app_id"
          }
          "secretKey" = "app-id"
        },
        {
          "remoteRef" = {
            "key"      = module.actions_runners_github_app_apc_self_hosted_runners_secret[0].secret_id
            "property" = "client_id"
          }
          "secretKey" = "client-id"
        },
        {
          "remoteRef" = {
            "key"      = module.actions_runners_github_app_apc_self_hosted_runners_secret[0].secret_id
            "property" = "installation_id"
          }
          "secretKey" = "installation-id" #checkov:skip=CKV_SECRET_6:secretKey is a reference to the key in the secret
        },
        {
          "remoteRef" = {
            "key"              = module.actions_runners_github_app_apc_self_hosted_runners_secret[0].secret_id
            "property"         = "private_key"
            "decodingStrategy" = "Base64"
          }
          "secretKey" = "private-key" #checkov:skip=CKV_SECRET_6:secretKey is a reference to the key in the secret
        },
      ]
    }
  }
}
