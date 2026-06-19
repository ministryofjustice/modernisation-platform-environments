resource "kubernetes_manifest" "alb_health_filter" {
  manifest = {
    apiVersion = "gateway.envoyproxy.io/v1alpha1"
    kind       = "HTTPRouteFilter"

    metadata = {
      name      = "alb-health-direct-response"
      namespace = kubernetes_namespace_v1.envoy_gateway_system.metadata[0].name
    }

    spec = {
      directResponse = {
        statusCode = 200
        body = {
          type   = "Inline"
          inline = "ok"
        }
      }
    }
  }

  depends_on = [helm_release.envoy_gateway]
}


resource "kubernetes_manifest" "alb_health_route" {
  manifest = {
    apiVersion = "gateway.networking.k8s.io/v1"
    kind       = "HTTPRoute"

    metadata = {
      name      = "alb-health"
      namespace = kubernetes_namespace_v1.envoy_gateway_system.metadata[0].name
    }

    spec = {
      parentRefs = [
        {
          name = kubernetes_manifest.gateway.manifest.metadata.name
          namespace = kubernetes_namespace_v1.envoy_gateway_system.metadata[0].name
        }
      ]

      rules = [
        {
          matches = [
            {
              path = {
                type  = "Exact"
                value = "/alb-health"
              }
            }
          ]

          filters = [
            {
              type = "ExtensionRef"

              extensionRef = {
                group = "gateway.envoyproxy.io"
                kind  = "HTTPRouteFilter"
                name  = kubernetes_manifest.alb_health_filter.manifest.metadata.name
              }
            }
          ]
        }
      ]
    }
  }

  depends_on = [
    kubernetes_manifest.gateway,
    kubernetes_manifest.alb_health_filter
  ]
}