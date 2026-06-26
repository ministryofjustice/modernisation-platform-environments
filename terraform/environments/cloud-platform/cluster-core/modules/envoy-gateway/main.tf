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
  namespace  = kubernetes_namespace_v1.envoy_gateway_system.metadata[0].name

  depends_on = [ kubernetes_namespace_v1.envoy_gateway_system ]

}

resource "kubernetes_manifest" "envoy_proxy" {
  manifest = {
    apiVersion = "gateway.envoyproxy.io/v1alpha1"
    kind       = "EnvoyProxy"

    metadata = {
      name      = "${var.gateway_name}-envoy-proxy"
      namespace = kubernetes_namespace_v1.envoy_gateway_system.metadata[0].name
    }

    spec = {
      provider = {
        type = "Kubernetes"

        kubernetes = {
          envoyDeployment = {
            replicas = var.envoy_proxy_replicas
          }

          envoyService = {
            type = "LoadBalancer"
            annotations = {
              "service.beta.kubernetes.io/aws-load-balancer-name"                  = "${var.cluster_name}-envoy-${var.gateway_name}"
              "service.beta.kubernetes.io/aws-load-balancer-scheme"                = "internet-facing"
              "service.beta.kubernetes.io/aws-load-balancer-nlb-target-type"       = "ip"
              "service.beta.kubernetes.io/aws-load-balancer-healthcheck-protocol"  = "TCP"
              "service.beta.kubernetes.io/aws-load-balancer-healthcheck-port"      = "traffic-port"
              "service.beta.kubernetes.io/aws-load-balancer-attributes"            = "load_balancing.cross_zone.enabled=true"
            }
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
      name = "${var.gateway_name}-gateway-class"
    }

    spec = {
      controllerName = "gateway.envoyproxy.io/gatewayclass-controller"

      parametersRef = {
        group     = "gateway.envoyproxy.io"
        kind      = "EnvoyProxy"
        name      = "${var.gateway_name}-envoy-proxy"
        namespace = kubernetes_namespace_v1.envoy_gateway_system.metadata[0].name
      }
    }
  }

  depends_on = [
    helm_release.envoy_gateway,
    kubernetes_manifest.envoy_proxy
  ]
}

# Platform Gateway.
#
# It owns physical ports only.
# Direct tenant HTTPRoute attachment is blocked by default because
# allowedRoutes is omitted, which defaults to Same namespace only.
#
# Tenants use either:
# - the platform default ListenerSet and wildcard certificate for quick start, or
# - create their own ListenerSet in their namespacefor custom cert/hostname control.

resource "kubernetes_manifest" "gateway" {
  manifest = {
    apiVersion = "gateway.networking.k8s.io/v1"
    kind       = "Gateway"

    metadata = {
      name      = var.gateway_name
      namespace = kubernetes_namespace_v1.envoy_gateway_system.metadata[0].name
    }

    spec = {
      gatewayClassName = kubernetes_manifest.gateway_class.manifest.metadata.name

      listeners = [
        {
          name     = "platform-http"
          protocol = "HTTP"
          port     = 80
        },
        # {
        #   # Use TLS here because hostname/cert mapping is supplied by ListenerSets.
        #   name     = "platform-tls"
        #   protocol = "TLS"
        #   port     = 443
        #   tls = {
        #     mode = "Passthrough"
        #   }
        # }
      ]

      # Any namespace can attach a ListenerSet to this platform Gateway.
      allowedListeners = {
        namespaces = {
          from = "All"
        }
      }
    }
  }

  depends_on = [kubernetes_manifest.gateway_class]
}

##########################################################
# Certificate resources for wildcard domain cert issuing #
##########################################################

resource "kubectl_manifest" "envoy_gateway_default_certificate" {
  yaml_body = templatefile("${path.module}/templates/default-certificate.yaml.tpl", {
    cluster_base_domain = var.cluster_base_domain
    gateway_name         = var.gateway_name
  })

  depends_on = [
    kubernetes_namespace_v1.envoy_gateway_system
  ]
}

resource "kubectl_manifest" "envoy_gateway_default_listenerset" {
  yaml_body = templatefile("${path.module}/templates/default-listenerset.yaml.tpl", {
    gateway_name             = kubernetes_manifest.gateway.manifest.metadata.name
    namespace                = kubernetes_namespace_v1.envoy_gateway_system.metadata[0].name
    listenerset_name         = "${var.gateway_name}-listenerset"
    tls_secret_name          = "${var.gateway_name}-certificate"
    base_domain              = var.cluster_base_domain
  })

  depends_on = [
    kubernetes_manifest.gateway,
    kubectl_manifest.envoy_gateway_default_certificate
  ]
}