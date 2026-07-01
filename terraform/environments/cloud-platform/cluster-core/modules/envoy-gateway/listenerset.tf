resource "kubectl_manifest" "envoy_gateway_default_listenerset" {
  yaml_body = templatefile("${path.module}/templates/default-listenerset.yaml.tpl", {
    listenerset_name = "${var.gateway_name}-listenerset"
    namespace        = kubernetes_namespace_v1.envoy_gateway_system.metadata[0].name
    gateway_name     = var.gateway_name
    base_domain      = var.cluster_base_domain
    tls_secret_name  = "default-certificate"
  })

  server_side_apply = true
  wait              = true

  depends_on = [
    kubectl_manifest.gateway,
    # kubernetes_manifest.envoy_gateway_default_certificate
  ]
}
