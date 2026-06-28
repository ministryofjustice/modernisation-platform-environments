resource "kubernetes_manifest" "envoy_gateway_default_certificate" {
  manifest = yamldecode(templatefile("${path.module}/templates/default-certificate.yaml.tpl", {
    namespace        = kubernetes_namespace_v1.envoy_gateway_system.metadata[0].name
    cluster_base_domain = var.cluster_base_domain
  }))

  depends_on = [
    kubernetes_namespace_v1.envoy_gateway_system
  ]
}
