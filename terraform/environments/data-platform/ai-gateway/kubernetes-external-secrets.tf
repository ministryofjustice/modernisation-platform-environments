resource "kubernetes_manifest" "external_secret_litellm_license" {
  depends_on = [module.ai_gateway_namespace]

  manifest = {
    apiVersion = "external-secrets.io/v1"
    kind       = "ExternalSecret"
    metadata = {
      name      = "litellm-license"
      namespace = module.ai_gateway_namespace.name
    }
    spec = {
      refreshInterval = "5m"
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
  depends_on = [module.ai_gateway_namespace]

  manifest = {
    apiVersion = "external-secrets.io/v1"
    kind       = "ExternalSecret"
    metadata = {
      name      = "litellm-salt-key"
      namespace = module.ai_gateway_namespace.name
    }
    spec = {
      refreshInterval = "5m"
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
  depends_on = [module.ai_gateway_namespace]

  manifest = {
    apiVersion = "external-secrets.io/v1"
    kind       = "ExternalSecret"
    metadata = {
      name      = "litellm-entra-id"
      namespace = module.ai_gateway_namespace.name
    }
    spec = {
      refreshInterval = "5m"
      secretStoreRef = {
        name = "aws-secretsmanager"
        kind = "ClusterSecretStore"
      }
      target = {
        name = "litellm-entra-id"
      }
      data = [
        {
          secretKey = "MICROSOFT_CLIENT_ID" #checkov:skip=CKV_SECRET_6:secretKey is a reference key, not secret material
          remoteRef = {
            key      = tostring(module.litellm_entra_id_secret.secret_id)
            property = "client_id"
          }
        },
        {
          secretKey = "MICROSOFT_CLIENT_SECRET" #checkov:skip=CKV_SECRET_6:secretKey is a reference key, not secret material
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
  depends_on = [module.ai_gateway_namespace]

  manifest = {
    apiVersion = "external-secrets.io/v1"
    kind       = "ExternalSecret"
    metadata = {
      name      = "aurora"
      namespace = module.ai_gateway_namespace.name
    }
    spec = {
      refreshInterval = "5m"
      secretStoreRef = {
        name = "aws-secretsmanager"
        kind = "ClusterSecretStore"
      }
      target = {
        name = "aurora"
      }
      data = concat(
        [
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
              property = "dummy_password"
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
        ],
        local.has_reader ? [
          {
            secretKey = "read-url"
            remoteRef = {
              key      = tostring(module.ai_gateway_aurora_secret.secret_id)
              property = "read-url"
            }
          }
        ] : []
      )
    }
  }
}

resource "kubernetes_manifest" "external_secret_elasticache" {
  depends_on = [module.ai_gateway_namespace]

  manifest = {
    apiVersion = "external-secrets.io/v1"
    kind       = "ExternalSecret"
    metadata = {
      name      = "elasticache"
      namespace = module.ai_gateway_namespace.name
    }
    spec = {
      refreshInterval = "5m"
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

resource "kubernetes_manifest" "external_secret_litellm_registry_client" {
  count = local.litellm_registry_credentials_enabled ? 1 : 0

  depends_on = [module.ai_gateway_namespace]

  manifest = {
    apiVersion = "external-secrets.io/v1"
    kind       = "ExternalSecret"
    metadata = {
      name      = "litellm-ops-client"
      namespace = module.ai_gateway_namespace.name
    }
    spec = {
      refreshInterval = "5m"
      secretStoreRef = {
        name = "aws-secretsmanager"
        kind = "ClusterSecretStore"
      }
      target = {
        name = "litellm-ops-client"
        template = {
          mergePolicy = "Merge"
          metadata = {
            labels = {
              "external-secrets.io/type" = "webhook"
            }
          }
        }
      }
      data = [
        for key in ["client_id", "client_secret", "token_url", "registry_url"] : {
          secretKey = key
          remoteRef = {
            key      = tostring(module.litellm_enterprise_registry_secret[0].secret_id)
            property = key
          }
        }
      ]
    }
  }

  wait {
    condition {
      type   = "Ready"
      status = "True"
    }
  }
}

resource "kubernetes_manifest" "webhook_litellm_registry_token" {
  count = local.litellm_registry_credentials_enabled ? 1 : 0

  depends_on = [kubernetes_manifest.external_secret_litellm_registry_client]

  manifest = {
    apiVersion = "generators.external-secrets.io/v1alpha1"
    kind       = "Webhook"
    metadata = {
      name      = "litellm-ops-token"
      namespace = module.ai_gateway_namespace.name
    }
    spec = {
      # Endpoints come from the synced client Secret; ESO does not URL-encode referenced secret values.
      url     = "{{ .client.token_url }}"
      method  = "POST"
      timeout = "30s"
      headers = {
        "Content-Type" = "application/x-www-form-urlencoded"
        Authorization  = "Basic {{ printf \"%s:%s\" .client.client_id .client.client_secret | b64enc }}"
      }
      body = "grant_type=client_credentials&scope=artifacts%2Ftoken"
      result = {
        jsonPath = "$"
      }
      secrets = [
        {
          name = "client"
          secretRef = {
            name = "litellm-ops-client"
          }
        }
      ]
    }
  }
}

resource "kubernetes_manifest" "external_secret_litellm_registry_access_token" {
  count = local.litellm_registry_credentials_enabled ? 1 : 0

  depends_on = [kubernetes_manifest.webhook_litellm_registry_token]

  manifest = {
    apiVersion = "external-secrets.io/v1"
    kind       = "ExternalSecret"
    metadata = {
      name      = "litellm-ops-access-token"
      namespace = module.ai_gateway_namespace.name
    }
    spec = {
      refreshPolicy   = "Periodic"
      refreshInterval = "15m"
      target = {
        name           = "litellm-ops-access-token"
        creationPolicy = "Owner"
        template = {
          engineVersion = "v2"
          metadata = {
            labels = {
              "external-secrets.io/type" = "webhook"
            }
          }
          data = {
            access_token = "{{ .access_token }}"
          }
        }
      }
      dataFrom = [
        {
          sourceRef = {
            generatorRef = {
              apiVersion = "generators.external-secrets.io/v1alpha1"
              kind       = "Webhook"
              name       = "litellm-ops-token"
            }
          }
        }
      ]
    }
  }

  wait {
    condition {
      type   = "Ready"
      status = "True"
    }
  }
}

resource "kubernetes_manifest" "webhook_litellm_registry_credentials" {
  count = local.litellm_registry_credentials_enabled ? 1 : 0

  depends_on = [
    kubernetes_manifest.external_secret_litellm_registry_client,
    kubernetes_manifest.external_secret_litellm_registry_access_token
  ]

  manifest = {
    apiVersion = "generators.external-secrets.io/v1alpha1"
    kind       = "Webhook"
    metadata = {
      name      = "litellm-ops-registry-credentials"
      namespace = module.ai_gateway_namespace.name
    }
    spec = {
      url     = "{{ .client.registry_url }}"
      method  = "GET"
      timeout = "30s"
      headers = {
        Authorization = "Bearer {{ .token.access_token }}"
      }
      result = {
        jsonPath = "$.ecr"
      }
      secrets = [
        {
          name = "client"
          secretRef = {
            name = "litellm-ops-client"
          }
        },
        {
          name = "token"
          secretRef = {
            name = "litellm-ops-access-token"
          }
        }
      ]
    }
  }
}

resource "kubernetes_manifest" "external_secret_litellm_registry_pull" {
  count = local.litellm_registry_credentials_enabled ? 1 : 0

  depends_on = [kubernetes_manifest.webhook_litellm_registry_credentials]

  manifest = {
    apiVersion = "external-secrets.io/v1"
    kind       = "ExternalSecret"
    metadata = {
      name      = "litellm-enterprise-pull"
      namespace = module.ai_gateway_namespace.name
    }
    spec = {
      refreshPolicy   = "Periodic"
      refreshInterval = "30m"
      target = {
        name           = "litellm-enterprise-pull"
        creationPolicy = "Owner"
        template = {
          engineVersion = "v2"
          type          = "kubernetes.io/dockerconfigjson"
          metadata = {
            annotations = {
              "litellm-registry-expires-at" = "{{ .expiresAt }}"
            }
          }
          data = {
            ".dockerconfigjson" = <<-EOT
              {"auths": {
                {{ .registry | toJson }}: {
                  "username": "AWS",
                  "password": {{ .password | toJson }},
                  "auth": {{ printf "AWS:%s" .password | b64enc | toJson }}
                }
              }}
            EOT
          }
        }
      }
      dataFrom = [
        {
          sourceRef = {
            generatorRef = {
              apiVersion = "generators.external-secrets.io/v1alpha1"
              kind       = "Webhook"
              name       = "litellm-ops-registry-credentials"
            }
          }
        }
      ]
    }
  }

  wait {
    condition {
      type   = "Ready"
      status = "True"
    }
  }
}
