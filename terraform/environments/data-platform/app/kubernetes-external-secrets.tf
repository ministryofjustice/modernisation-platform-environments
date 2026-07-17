resource "kubernetes_manifest" "app_secrets_secret" {
  #checkov:skip=CKV_SECRET_6:secretKey is a reference to the key in the secret

  manifest = {
    "apiVersion" = "external-secrets.io/v1"
    "kind"       = "ExternalSecret"
    "metadata" = {
      "name"      = "app-secrets"
      "namespace" = module.app_namespace.name
    }
    "spec" = {
      "refreshInterval" = "1m"
      "secretStoreRef" = {
        "kind" = "ClusterSecretStore"
        "name" = "aws-secretsmanager"
      }
      "target" = {
        "name" = "app-secrets"
      }
      "data" = [
        {
          "remoteRef" = {
            "key"      = tostring(module.app_secrets.secret_id)
            "property" = "secret_key"
          }
          "secretKey" = "secret-key"
        },
        {
          "remoteRef" = {
            "key"      = tostring(module.app_secrets.secret_id)
            "property" = "sentry_dsn"
          }
          "secretKey" = "sentry-dsn"
        },
        {
          "remoteRef" = {
            "key" = data.aws_secretsmanager_secret.ai_gateway_litellm_master_key.id
          }
          "secretKey" = "ai-gateway-master-key"
        }
      ]
    }
  }
}

resource "kubernetes_manifest" "app_rds_secret" {
  #checkov:skip=CKV_SECRET_6:secretKey is a reference to the key in the secret

  manifest = {
    "apiVersion" = "external-secrets.io/v1"
    "kind"       = "ExternalSecret"
    "metadata" = {
      "name"      = "app-rds"
      "namespace" = module.app_namespace.name
    }
    "spec" = {
      "refreshInterval" = "1m"
      "secretStoreRef" = {
        "kind" = "ClusterSecretStore"
        "name" = "aws-secretsmanager"
      }
      "target" = {
        "name" = "app-rds"
      }
      "data" = [
        {
          "remoteRef" = {
            "key"      = tostring(module.app_rds_credentials.secret_id)
            "property" = "username"
          }
          "secretKey" = "username"
        },
        {
          "remoteRef" = {
            "key"      = tostring(module.app_rds_credentials.secret_id)
            "property" = "password"
          }
          "secretKey" = "password"
        },
        {
          "remoteRef" = {
            "key"      = tostring(module.app_rds_credentials.secret_id)
            "property" = "host"
          }
          "secretKey" = "host"
        },
        {
          "remoteRef" = {
            "key"      = tostring(module.app_rds_credentials.secret_id)
            "property" = "port"
          }
          "secretKey" = "port"
        },
        {
          "remoteRef" = {
            "key"      = tostring(module.app_rds_credentials.secret_id)
            "property" = "dbname"
          }
          "secretKey" = "dbname"
        },
      ]
    }
  }
}
