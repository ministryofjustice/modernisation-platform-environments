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

resource "kubectl_manifest" "envoy_proxy" {
  yaml_body = templatefile("${path.module}/templates/envoy-proxy.yaml.tpl", {
    gateway_name         = var.gateway_name
    namespace            = kubernetes_namespace_v1.envoy_gateway_system.metadata[0].name
    envoy_proxy_replicas = var.envoy_proxy_replicas
    cluster_name         = var.cluster_name
  })

  server_side_apply = true
  wait              = true

  depends_on = [helm_release.envoy_gateway]
}

resource "kubectl_manifest" "gateway_class" {
  yaml_body = templatefile("${path.module}/templates/gateway-class.yaml.tpl", {
    gateway_class_name = "${var.gateway_name}-gateway-class"
    envoy_proxy_name   = "${var.gateway_name}-envoy-proxy"
    namespace          = kubernetes_namespace_v1.envoy_gateway_system.metadata[0].name
  })

  server_side_apply = true
  wait              = true

  depends_on = [
    helm_release.envoy_gateway,
    kubectl_manifest.envoy_proxy
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
resource "kubectl_manifest" "gateway" {
  yaml_body = templatefile("${path.module}/templates/gateway.yaml.tpl", {
    gateway_name       = var.gateway_name
    namespace          = kubernetes_namespace_v1.envoy_gateway_system.metadata[0].name
    gateway_class_name = "${var.gateway_name}-gateway-class"
  })

  server_side_apply = true
  wait              = true

  depends_on = [kubectl_manifest.gateway_class]
}
