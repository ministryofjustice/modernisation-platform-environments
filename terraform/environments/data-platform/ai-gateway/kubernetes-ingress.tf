resource "kubernetes_manifest" "http_route" {
  depends_on = [
    kubernetes_namespace_v1.ai_gateway,
    kubernetes_manifest.ai_gateway
  ]

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
          name      = "ai-gateway"
          namespace = "ai-gateway"
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
                path = {
                  type            = "ReplaceFullPath"
                  replaceFullPath = "/"
                }
                statusCode = 302
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
  depends_on = [
    kubernetes_namespace_v1.ai_gateway,
    kubernetes_manifest.ai_gateway
  ]

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
          name      = "ai-gateway"
          namespace = "ai-gateway"
        }
      ]
      hostnames = ["admin.${local.environment_configuration.ai_gateway_hostname}"]
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
                path = {
                  type            = "ReplaceFullPath"
                  replaceFullPath = "/"
                }
                statusCode = 302
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
  depends_on = [kubernetes_namespace_v1.ai_gateway]

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
          fromCIDRSet = [{ cidr = data.aws_vpc.eks.cidr_block }]
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
  depends_on = [kubernetes_namespace_v1.ai_gateway]

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
          fromCIDRSet = [{ cidr = data.aws_vpc.eks.cidr_block }]
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
