resource "kubernetes_manifest" "user_test_namespace" {
  manifest = yamldecode(file("${path.module}/user-manifests/namespace.yaml"))
}

resource "kubernetes_manifest" "user_test_deployment" {
  manifest = yamldecode(file("${path.module}/user-manifests/deployment.yaml"))

  depends_on = [
    kubernetes_manifest.user_test_namespace,
  ]
}

resource "kubernetes_manifest" "user_test_service" {
  manifest = yamldecode(file("${path.module}/user-manifests/service.yaml"))

  depends_on = [
    kubernetes_manifest.user_test_namespace,
    kubernetes_manifest.user_test_deployment,
  ]
}

resource "kubernetes_manifest" "user_test_http_routes" {
  for_each = local.echo_hostnames

  manifest = yamldecode(templatefile("${path.module}/user-manifests/http-route.yaml", {
    route_name = "${each.key}-route"
    hostname   = each.value
  }))

  depends_on = [
    kubernetes_manifest.user_test_namespace,
    kubernetes_manifest.user_test_service,
    kubectl_manifest.gateway_platform,
  ]
}
