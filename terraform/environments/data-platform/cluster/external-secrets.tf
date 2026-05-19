resource "kubernetes_manifest" "headlamp_oidc_external_secret" {
  manifest = {
    apiVersion = "external-secrets.io/v1"
    kind       = "ExternalSecret"

    metadata = {
      name      = "headlamp-oidc"
      namespace = module.headlamp_namespace.name
    }

    spec = {
      refreshInterval = "1h"

      secretStoreRef = {
        name = "aws-secretsmanager"
        kind = "ClusterSecretStore"
      }

      target = {
        name           = "oidc"
        creationPolicy = "Owner"
      }

      data = [
        {
          secretKey = "OIDC_CLIENT_ID"
          remoteRef = {
            key      = "headlamp/headlamp-entra-id"
            property = "client_id"
          }
        },
        {
          secretKey = "OIDC_CLIENT_SECRET"
          remoteRef = {
            key      = "headlamp/headlamp-entra-id"
            property = "client_secret"
          }
        },
        {
          secretKey = "OIDC_ISSUER_URL"
          remoteRef = {
            key      = "headlamp/headlamp-entra-id"
            property = "issuer_url"
          }
        }
      ]
    }
  }
}