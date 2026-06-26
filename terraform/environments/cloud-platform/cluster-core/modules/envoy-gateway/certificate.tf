resource "kubernetes_manifest" "envoy_gateway_default_certificate" {
  manifest = {
    apiVersion = "cert-manager.io/v1"
    kind       = "Certificate"

    metadata = {
      name      = "default"
      namespace = kubernetes_namespace_v1.envoy_gateway_system.metadata[0].name
    }

    spec = {
      secretName = "${var.gateway_name}-certificate"

      issuerRef = {
        name = "letsencrypt-production"
        kind = "ClusterIssuer"
      }

      dnsNames = [
        "*.apps.${var.cluster_base_domain}",
        "*.${var.cluster_base_domain}"
      ]
    }
  }

  depends_on = [
    kubernetes_namespace_v1.envoy_gateway_system
  ]
}
