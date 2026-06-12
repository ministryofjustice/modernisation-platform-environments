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
    route_name   = "${each.key}-route"
    hostname     = each.value
    gateway_name = "shared-alb"
  }))

  depends_on = [
    kubernetes_manifest.user_test_namespace,
    kubernetes_manifest.user_test_service,
    kubectl_manifest.gateway_platform,
  ]
}

# Scenario 9: routes attached to the second Gateway (shared-alb-b) for the
# multi-Gateway feasibility test. Kept as a separate resource block to make the
# layout explicit (Gateway A workloads versus Gateway B workloads).
resource "kubernetes_manifest" "user_test_http_routes_b" {
  for_each = local.echo_b_hostnames

  manifest = yamldecode(templatefile("${path.module}/user-manifests/http-route.yaml", {
    route_name   = "${each.key}-route"
    hostname     = each.value
    gateway_name = "shared-alb-b"
  }))

  depends_on = [
    kubernetes_manifest.user_test_namespace,
    kubernetes_manifest.user_test_service,
    kubectl_manifest.gateway_b,
  ]
}
