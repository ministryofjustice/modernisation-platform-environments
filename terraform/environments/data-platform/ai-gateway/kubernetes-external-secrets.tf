resource "kubernetes_manifest" "external_secret_litellm_license" {
  depends_on = [kubernetes_namespace_v1.ai_gateway]

  manifest = {
    apiVersion = "external-secrets.io/v1"
    kind       = "ExternalSecret"
    metadata = {
      name      = "litellm-license"
      namespace = "ai-gateway"
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
          secretKey = "LITELLM_LICENSE"
          remoteRef = {
            key = tostring(module.litellm_license_secret.secret_id)
          }
        }
      ]
    }
  }
}

resource "kubernetes_manifest" "external_secret_litellm_salt_key" {
  depends_on = [kubernetes_namespace_v1.ai_gateway]

  manifest = {
    apiVersion = "external-secrets.io/v1"
    kind       = "ExternalSecret"
    metadata = {
      name      = "litellm-salt-key"
      namespace = "ai-gateway"
    }
    spec = {
      refreshInterval = "1h"
      secretStoreRef = {
        name = "aws-secretsmanager"
        kind = "ClusterSecretStore"
      }
      target = {
        name = "litellm-salt-key"
      }
      data = [
        {
          secretKey = "LITELLM_SALT_KEY"
          remoteRef = {
            key = tostring(module.litellm_salt_key_secret.secret_id)
          }
        }
      ]
    }
  }
}

resource "kubernetes_manifest" "external_secret_litellm_entra_id" {
  depends_on = [kubernetes_namespace_v1.ai_gateway]

  manifest = {
    apiVersion = "external-secrets.io/v1"
    kind       = "ExternalSecret"
    metadata = {
      name      = "litellm-entra-id"
      namespace = "ai-gateway"
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


resource "kubernetes_manifest" "external_secret_aurora" {
  depends_on = [kubernetes_namespace_v1.ai_gateway]

  manifest = {
    apiVersion = "external-secrets.io/v1"
    kind       = "ExternalSecret"
    metadata = {
      name      = "aurora"
      namespace = "ai-gateway"
    }
    spec = {
      refreshInterval = "1h"
      secretStoreRef = {
        name = "aws-secretsmanager"
        kind = "ClusterSecretStore"
      }
      target = {
        name = "aurora"
      }
      data = [
        {
          secretKey = "username"
          remoteRef = {
            key      = tostring(module.ai_gateway_aurora_secret.secret_id)
            property = "username"
          }
        },
        {
          secretKey = "password"
          remoteRef = {
            key      = tostring(module.ai_gateway_aurora_secret.secret_id)
            property = "password"
          }
        },
        {
          secretKey = "host"
          remoteRef = {
            key      = tostring(module.ai_gateway_aurora_secret.secret_id)
            property = "host"
          }
        },
        {
          secretKey = "port"
          remoteRef = {
            key      = tostring(module.ai_gateway_aurora_secret.secret_id)
            property = "port"
          }
        },
        {
          secretKey = "dbname"
          remoteRef = {
            key      = tostring(module.ai_gateway_aurora_secret.secret_id)
            property = "dbname"
          }
        }
      ]
    }
  }
}

resource "kubernetes_manifest" "external_secret_elasticache" {
  depends_on = [kubernetes_namespace_v1.ai_gateway]

  manifest = {
    apiVersion = "external-secrets.io/v1"
    kind       = "ExternalSecret"
    metadata = {
      name      = "elasticache"
      namespace = "ai-gateway"
    }
    spec = {
      refreshInterval = "1h"
      secretStoreRef = {
        name = "aws-secretsmanager"
        kind = "ClusterSecretStore"
      }
      target = {
        name = "elasticache"
      }
      data = [
        {
          secretKey = "primary_endpoint_address"
          remoteRef = {
            key      = tostring(module.ai_gateway_elasticache_secret.secret_id)
            property = "primary_endpoint_address"
          }
        },
        {
          secretKey = "auth_token"
          remoteRef = {
            key      = tostring(module.ai_gateway_elasticache_secret.secret_id)
            property = "auth_token"
          }
        },
        {
          secretKey = "port"
          remoteRef = {
            key      = tostring(module.ai_gateway_elasticache_secret.secret_id)
            property = "port"
          }
        }
      ]
    }
  }
}
