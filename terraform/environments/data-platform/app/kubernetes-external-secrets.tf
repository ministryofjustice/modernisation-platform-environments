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
      "data" = concat([
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
            "key"      = tostring(module.app_secrets.secret_id)
            "property" = "azure_authority"
          }
          "secretKey" = "azure-authority" #checkov:skip=CKV_SECRET_6:secretKey is a reference to the key in the secret
        },
        {
          "remoteRef" = {
            "key"      = tostring(module.app_secrets.secret_id)
            "property" = "azure_client_id"
          }
          "secretKey" = "azure-client-id" #checkov:skip=CKV_SECRET_6:secretKey is a reference to the key in the secret
        },
        {
          "remoteRef" = {
            "key"      = tostring(module.app_secrets.secret_id)
            "property" = "azure_client_secret"
          }
          "secretKey" = "azure-client-secret" #checkov:skip=CKV_SECRET_6:secretKey is a reference to the key in the secret
        },
        {
          "remoteRef" = {
            "key"      = tostring(module.app_secrets.secret_id)
            "property" = "field_encryption_key"
          }
          "secretKey" = "field-encryption-key" #checkov:skip=CKV_SECRET_6:secretKey is a reference to the key in the secret
        },
        {
          "remoteRef" = {
            "key" = data.aws_secretsmanager_secret.ai_gateway_litellm_master_key.id
          }
          "secretKey" = format("ai-gateway-%s", "master-key")
        },
        {
          "remoteRef" = {
            "key"      = tostring(module.app_secrets.secret_id)
            "property" = "notify_api_key"
          }
          "secretKey" = "notify-api-key" #checkov:skip=CKV_SECRET_6:secretKey is a reference to the key in the secret
        },
        {
          "remoteRef" = {
            "key"      = tostring(module.app_secrets.secret_id)
            "property" = "notify_project_member_added_template_id"
          }
          "secretKey" = "notify-project-member-added-template-id" #checkov:skip=CKV_SECRET_6:secretKey is a reference to the key in the secret
        },
        {
          "remoteRef" = {
            "key"      = tostring(module.app_secrets.secret_id)
            "property" = "notify_project_member_removed_template_id"
          }
          "secretKey" = "notify-project-member-removed-template-id" #checkov:skip=CKV_SECRET_6:secretKey is a reference to the key in the secret
        },
        {
          "remoteRef" = {
            "key"      = tostring(module.app_secrets.secret_id)
            "property" = "notify_budget_alert_template_id"
          }
          "secretKey" = "notify-budget-alert-template-id" #checkov:skip=CKV_SECRET_6:secretKey is a reference to the key in the secret
        },
      ], local.environment_configuration.app_e2e_auth_enabled ? [
        {
          "remoteRef" = {
            "key"      = tostring(module.app_secrets.secret_id)
            "property" = "e2e_auth_token"
          }
          "secretKey" = "e2e-auth-token" #checkov:skip=CKV_SECRET_6:secretKey is a reference to the key in the secret
        },
        {
          "remoteRef" = {
            "key"      = tostring(module.app_secrets.secret_id)
            "property" = "e2e_user_email"
          }
          "secretKey" = "e2e-user-email" #checkov:skip=CKV_SECRET_6:secretKey is a reference to the key in the secret
        },
      ] : [])
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
