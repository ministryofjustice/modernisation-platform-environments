resource "kubernetes_namespace_v1" "envoy-gateway-system" {
  metadata {
    name = "envoy-gateway-system"

    labels = {
      "name"                                            = "envoy-gateway-system"
      "pod-security.kubernetes.io/enforce"              = "privileged"
    }
  }
}

resource "helm_release" "envoy-gateway" {
  name       = "envoy-gateway"
  chart      = "gateway-helm"
  repository = "oci://docker.io/envoyproxy/"
  version    = "1.8.0"
  namespace  = "envoy-gateway-system"

  depends_on = [ kubernetes_namespace_v1.envoy-gateway-system ]

}