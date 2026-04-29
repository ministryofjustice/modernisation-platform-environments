resource "kubernetes_manifest" "external_secret_litellm_license" {
  manifest = {
    apiVersion = "external-secrets.io/v1"
    kind       = "ExternalSecret"
    metadata = {
      name      = "litellm-license"
      namespace = "llm-gateway"
    }
    spec = {
      refreshInterval = "1h"
      secretStoreRef = {
        name = "aws-secretsmanager"
        kind = "ClusterSecretStore"
      }
      target = {
        name = "litellm-license"
      }
      data = [
        {
          secretKey = "license"
          remoteRef = {
            key = tostring(module.litellm_license_secret.secret_id)
          }
        }
      ]
    }
  }
}

resource "kubernetes_manifest" "external_secret_litellm_entra_id" {
  manifest = {
    apiVersion = "external-secrets.io/v1"
    kind       = "ExternalSecret"
    metadata = {
      name      = "litellm-entra-id"
      namespace = "llm-gateway"
    }
    spec = {
      refreshInterval = "1h"
      secretStoreRef = {
        name = "aws-secretsmanager"
        kind = "ClusterSecretStore"
      }
      target = {
        name = "litellm-entra-id"
      }
      data = [
        {
          secretKey = "MICROSOFT_CLIENT_ID"
          remoteRef = {
            key      = tostring(module.litellm_entra_id_secret.secret_id)
            property = "client_id"
          }
        },
        {
          secretKey = "MICROSOFT_CLIENT_SECRET"
          remoteRef = {
            key      = tostring(module.litellm_entra_id_secret.secret_id)
            property = "client_secret"
          }
        },
        {
          secretKey = "MICROSOFT_TENANT"
          remoteRef = {
            key      = tostring(module.litellm_entra_id_secret.secret_id)
            property = "tenant_id"
          }
        },
        {
          secretKey = "PROXY_ADMIN_ID"
          remoteRef = {
            key      = tostring(module.litellm_entra_id_secret.secret_id)
            property = "proxy_admin_id"
          }
        }
      ]
    }
  }
}

resource "kubernetes_manifest" "external_secret_justiceai_azure_openai" {
  manifest = {
    apiVersion = "external-secrets.io/v1"
    kind       = "ExternalSecret"
    metadata = {
      name      = "justiceai-azure-openai"
      namespace = "llm-gateway"
    }
    spec = {
      refreshInterval = "1h"
      secretStoreRef = {
        name = "aws-secretsmanager"
        kind = "ClusterSecretStore"
      }
      target = {
        name = "justiceai-azure-openai"
      }
      data = [
        {
          secretKey = "AZURE_OPENAI_API_BASE"
          remoteRef = {
            key      = tostring(module.justiceai_azure_openai_secret.secret_id)
            property = "api_base"
          }
        },
        {
          secretKey = "AZURE_OPENAI_API_KEY"
          remoteRef = {
            key      = tostring(module.justiceai_azure_openai_secret.secret_id)
            property = "api_key"
          }
        }
      ]
    }
  }
}

resource "kubernetes_manifest" "external_secret_azure_openai" {
  manifest = {
    apiVersion = "external-secrets.io/v1"
    kind       = "ExternalSecret"
    metadata = {
      name      = "azure-openai"
      namespace = "llm-gateway"
    }
    spec = {
      refreshInterval = "1h"
      secretStoreRef = {
        name = "aws-secretsmanager"
        kind = "ClusterSecretStore"
      }
      target = {
        name = "azure-openai"
      }
      data = [
        {
          secretKey = "AZURE_OPENAI_API_BASE"
          remoteRef = {
            key      = tostring(module.azure_openai_secret.secret_id)
            property = "api_base"
          }
        },
        {
          secretKey = "AZURE_OPENAI_API_KEY"
          remoteRef = {
            key      = tostring(module.azure_openai_secret.secret_id)
            property = "api_key"
          }
        }
      ]
    }
  }
}

resource "kubernetes_manifest" "external_secret_rds" {
  manifest = {
    apiVersion = "external-secrets.io/v1"
    kind       = "ExternalSecret"
    metadata = {
      name      = "rds"
      namespace = "llm-gateway"
    }
    spec = {
      refreshInterval = "1h"
      secretStoreRef = {
        name = "aws-secretsmanager"
        kind = "ClusterSecretStore"
      }
      target = {
        name = "rds"
      }
      data = [
        {
          secretKey = "username"
          remoteRef = {
            key      = tostring(module.rds_secret.secret_id)
            property = "username"
          }
        },
        {
          secretKey = "password"
          remoteRef = {
            key      = tostring(module.rds_secret.secret_id)
            property = "password"
          }
        },
        {
          secretKey = "host"
          remoteRef = {
            key      = tostring(module.rds_secret.secret_id)
            property = "host"
          }
        },
        {
          secretKey = "port"
          remoteRef = {
            key      = tostring(module.rds_secret.secret_id)
            property = "port"
          }
        },
        {
          secretKey = "dbname"
          remoteRef = {
            key      = tostring(module.rds_secret.secret_id)
            property = "dbname"
          }
        }
      ]
    }
  }
}
