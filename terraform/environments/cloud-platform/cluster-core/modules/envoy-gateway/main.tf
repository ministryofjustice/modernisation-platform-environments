resource "kubernetes_namespace_v1" "envoy_gateway_system" {
  metadata {
    name = "envoy-gateway-system"

    labels = {
      "name"                                            = "envoy-gateway-system"
      "pod-security.kubernetes.io/enforce"              = "privileged"
    }
  }
}

resource "helm_release" "envoy_gateway" {
  name       = "envoy-gateway"
  chart      = "gateway-helm"
  repository = "oci://docker.io/envoyproxy/"
  version    = "1.8.1"
  namespace  = "envoy-gateway-system"

  depends_on = [ kubernetes_namespace_v1.envoy_gateway_system ]

}

resource "kubernetes_manifest" "envoy_proxy" {
  manifest = {
    apiVersion = "gateway.envoyproxy.io/v1alpha1"
    kind       = "EnvoyProxy"

    metadata = {
      name      = "shared-alb-proxy"
      namespace = "envoy-gateway-system"
    }

    spec = {
      provider = {
        type = "Kubernetes"

        kubernetes = {
          envoyDeployment = {
            replicas = 3
          }

          envoyService = {
            type = "ClusterIP"
            name = "envoy-gateway-proxy-alb"
          }
        }
      }
    }
  }

  depends_on = [helm_release.envoy_gateway]
}
resource "kubernetes_manifest" "gateway_class" {
  manifest = {
    apiVersion = "gateway.networking.k8s.io/v1"
    kind       = "GatewayClass"

    metadata = {
      name = "default-gateway-class"
    }

    spec = {
      controllerName = "gateway.envoyproxy.io/gatewayclass-controller"

      parametersRef = {
        group     = "gateway.envoyproxy.io"
        kind      = "EnvoyProxy"
        name      = "shared-alb-proxy"
        namespace = "envoy-gateway-system"
      }
    }
  }

  depends_on = [
    helm_release.envoy_gateway,
    kubernetes_manifest.envoy_proxy
  ]
}

resource "kubernetes_manifest" "gateway" {
  manifest = {
    apiVersion = "gateway.networking.k8s.io/v1"
    kind       = "Gateway"

    metadata = {
      name      = "default"
      namespace = kubernetes_namespace_v1.envoy_gateway_system.metadata[0].name
    }

    spec = {
      gatewayClassName = kubernetes_manifest.gateway_class.manifest.metadata.name

      listeners = [
        {
          name     = "http"
          protocol = "HTTP"
          port     = 80

          allowedRoutes = {
            namespaces = {
              from = "All"
            }
          }
        }
      ]
    }
  }

  depends_on = [kubernetes_manifest.gateway_class]
}