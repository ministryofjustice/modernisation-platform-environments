resource "kubernetes_manifest" "envoy_gateway_default_listenerset" {
  manifest = {
    apiVersion = "gateway.networking.k8s.io/v1"
    kind       = "ListenerSet"

    metadata = {
      name      = "${var.gateway_name}-listenerset"
      namespace = kubernetes_namespace_v1.envoy_gateway_system.metadata[0].name
    }

    spec = {
      parentRef = {
        group     = "gateway.networking.k8s.io"
        kind      = "Gateway"
        name      = kubernetes_manifest.gateway.manifest.metadata.name
        namespace = kubernetes_namespace_v1.envoy_gateway_system.metadata[0].name
      }

      listeners = [
        {
          name     = "http"
          protocol = "HTTP"
          port     = 80
          hostname = "*.apps.${var.cluster_base_domain}"

          allowedRoutes = {
            namespaces = {
              from = "All"
            }
            kinds = [
              {
                group = "gateway.networking.k8s.io"
                kind  = "HTTPRoute"
              }
            ]
          }
        },
        {
          name     = "https"
          protocol = "HTTPS"
          port     = 443
          hostname = "*.apps.${var.cluster_base_domain}"

          tls = {
            mode = "Terminate"

            certificateRefs = [
              {
                group = ""
                kind  = "Secret"
                name  = kubernetes_manifest.envoy_gateway_default_certificate.manifest.spec.secretName
              }
            ]
          }

          allowedRoutes = {
            namespaces = {
              from = "All"
            }
            kinds = [
              {
                group = "gateway.networking.k8s.io"
                kind  = "HTTPRoute"
              }
            ]
          }
        }
      ]
    }
  }

  depends_on = [
    kubernetes_manifest.gateway,
    kubernetes_manifest.envoy_gateway_default_certificate
  ]
}
