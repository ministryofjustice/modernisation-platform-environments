resource "kubernetes_manifest" "envoy_gateway_default_listenerset" {
  manifest = yamldecode(templatefile("${path.module}/templates/default-listenerset.yaml.tpl", {
    listenerset_name = "${var.gateway_name}-listenerset"
    namespace        = kubernetes_namespace_v1.envoy_gateway_system.metadata[0].name
    gateway_name     = kubernetes_manifest.gateway.manifest.metadata.name
    base_domain      = var.cluster_base_domain
    tls_secret_name  = kubernetes_manifest.envoy_gateway_default_certificate.manifest.spec.secretName
  }))

  depends_on = [
    kubernetes_manifest.gateway,
    kubernetes_manifest.envoy_gateway_default_certificate
  ]
}
