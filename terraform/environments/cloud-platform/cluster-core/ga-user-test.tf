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

resource "kubernetes_manifest" "user_test_http_route" {
  manifest = yamldecode(file("${path.module}/user-manifests/http-route.yaml"))

  depends_on = [
    kubernetes_manifest.user_test_namespace,
    kubernetes_manifest.user_test_service,
    kubectl_manifest.gateway_platform,
  ]
}
