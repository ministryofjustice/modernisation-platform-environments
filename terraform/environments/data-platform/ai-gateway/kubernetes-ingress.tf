resource "kubernetes_manifest" "http_route" {
  manifest = {
    apiVersion = "gateway.networking.k8s.io/v1"
    kind       = "HTTPRoute"
    metadata = {
      name      = "litellm"
      namespace = "ai-gateway"
    }
    spec = {
      parentRefs = [
        {
          name      = "shared-gateway"
          namespace = "shared-services"
        }
      ]
      hostnames = [local.environment_configuration.ai_gateway_hostname]
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

resource "kubernetes_manifest" "http_route_admin" {
  manifest = {
    apiVersion = "gateway.networking.k8s.io/v1"
    kind       = "HTTPRoute"
    metadata = {
      name      = "litellm-admin"
      namespace = "ai-gateway"
    }
    spec = {
      parentRefs = [
        {
          name      = "shared-gateway"
          namespace = "shared-services"
        }
      ]
      hostnames = [local.environment_configuration.ai_gateway_admin_hostname]
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
              name = "litellm-admin"
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
      namespace = "ai-gateway"
    }
    spec = {
      endpointSelector = {
        matchLabels = {
          "app.kubernetes.io/name" = "litellm"
        }
      }
      ingress = [
        {
          fromCIDRSet = [for cidr in local.environment_configuration.ai_gateway_ingress_allowlist : { cidr = cidr }]
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

resource "kubernetes_manifest" "cilium_network_policy_admin" {
  manifest = {
    apiVersion = "cilium.io/v2"
    kind       = "CiliumNetworkPolicy"
    metadata = {
      name      = "litellm-admin-ingress-allowlist"
      namespace = "ai-gateway"
    }
    spec = {
      endpointSelector = {
        matchLabels = {
          "app.kubernetes.io/name" = "litellm-admin"
        }
      }
      ingress = [
        {
          fromCIDRSet = [for cidr in local.environment_configuration.ai_gateway_admin_ingress_allowlist : { cidr = cidr }]
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
