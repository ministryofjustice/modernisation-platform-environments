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

resource "kubernetes_ingress_v1" "litellm_cloud_platform" {
  count = terraform.workspace == "data-platform-development" ? 1 : 0

  provider = kubernetes.cloud_platform

  metadata {
    name      = "litellm"
    namespace = jsondecode(data.aws_secretsmanager_secret_version.cloud_platform_live_namespace[0].secret_string)["namespace"]
    annotations = {
      "external-dns.alpha.kubernetes.io/aws-weight"        = "100"
      "external-dns.alpha.kubernetes.io/hostname"          = local.environment_configuration.cloud_platform_hostname
      "external-dns.alpha.kubernetes.io/set-identifier"    = "litellm-${local.application_name}-${local.component_name}-${local.environment}-green"
      "nginx.ingress.kubernetes.io/whitelist-source-range" = join(",", local.environment_configuration.llm_gateway_ingress_allowlist)
    }
    labels = {}
  }

  spec {
    ingress_class_name = "default"
    rule {
      host = local.environment_configuration.cloud_platform_hostname
      http {
        path {
          path      = "/"
          path_type = "ImplementationSpecific"
          backend {
            service {
              name = "litellm"
              port {
                number = 4000
              }
            }
          }
        }
        // This path is to stop metrics being accessed externally
        path {
          path      = "/metrics"
          path_type = "ImplementationSpecific"
          backend {
            service {
              name = "blackhole"
              port {
                number = 8080
              }
            }
          }
        }
      }
    }

    tls {
      hosts       = [local.environment_configuration.cloud_platform_hostname]
      secret_name = "llms-gateway-tls"
    }
  }
}
