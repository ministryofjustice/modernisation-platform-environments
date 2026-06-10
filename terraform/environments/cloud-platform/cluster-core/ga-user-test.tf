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
  manifest = yamldecode(templatefile("${path.module}/user-manifests/http-route.yaml", {
    route_name = "echo-route"
    hostname   = local.echo2_hostname
  }))

  depends_on = [
    kubernetes_manifest.user_test_namespace,
    kubernetes_manifest.user_test_service,
    kubectl_manifest.gateway_platform,
  ]
}

resource "kubernetes_manifest" "user_test_http_route_echo3" {
  manifest = yamldecode(templatefile("${path.module}/user-manifests/http-route.yaml", {
    route_name = "echo3-route"
    hostname   = local.echo3_hostname
  }))

  depends_on = [
    kubernetes_manifest.user_test_namespace,
    kubernetes_manifest.user_test_service,
    kubectl_manifest.gateway_platform,
  ]
}
