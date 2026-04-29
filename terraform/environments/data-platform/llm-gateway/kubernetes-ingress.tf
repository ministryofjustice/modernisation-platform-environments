resource "kubernetes_manifest" "http_route" {
  manifest = {
    apiVersion = "gateway.networking.k8s.io/v1"
    kind       = "HTTPRoute"
    metadata = {
      name      = "litellm"
      namespace = "llm-gateway"
    }
    spec = {
      parentRefs = [
        {
          name      = "shared-gateway"
          namespace = "shared-services"
        }
      ]
      hostnames = [local.environment_configuration.llm_gateway_hostname]
      rules = [
        {
          matches = [
            {
              path = {
                type  = "PathPrefix"
                value = "/metrics"
              }
            }
          ]
          filters = [
            {
              type = "ResponseHeaderModifier"
              responseHeaderModifier = {
                set = []
              }
            },
            {
              type = "RequestRedirect"
              requestRedirect = {
                statusCode = 404
              }
            }
          ]
        },
        {
          matches = [
            {
              path = {
                type  = "PathPrefix"
                value = "/"
              }
            }
          ]
          backendRefs = [
            {
              name = "litellm"
              port = 4000
            }
          ]
        }
      ]
    }
  }
}

resource "kubernetes_manifest" "cilium_network_policy" {
  manifest = {
    apiVersion = "cilium.io/v2"
    kind       = "CiliumNetworkPolicy"
    metadata = {
      name      = "litellm-ingress-allowlist"
      namespace = "llm-gateway"
    }
    spec = {
      endpointSelector = {
        matchLabels = {
          "app.kubernetes.io/name" = "litellm"
        }
      }
      ingress = [
        {
          fromCIDRSet = [for cidr in local.environment_configuration.llm_gateway_ingress_allowlist : { cidr = cidr }]
          toPorts = [
            {
              ports = [
                {
                  port     = "4000"
                  protocol = "TCP"
                }
              ]
            }
          ]
        },
        {
          fromEndpoints = [
            {
              matchLabels = {
                "io.cilium.k8s.policy.cluster" = "data-platform-${local.environment}"
              }
            }
          ]
          toPorts = [
            {
              ports = [
                {
                  port     = "4000"
                  protocol = "TCP"
                }
              ]
            }
          ]
        }
      ]
    }
  }
}
