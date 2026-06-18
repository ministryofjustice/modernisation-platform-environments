# proxy
resource "kubernetes_manifest" "envoy_testing" {
  manifest = yamldecode(file("./manifests/envoy-proxy.yaml"))
}

# gateway class
resource "kubernetes_manifest" "envoy_gateway_class" {
  manifest = yamldecode(file("./manifests/envoy-gateway-class.yaml"))
}
# gateway
resource "kubernetes_manifest" "envoy_gateway" {
  manifest = yamldecode(file("./manifests/envoy-gateway.yaml"))
}

# shared envoy service for alb ingress
resource "kubernetes_manifest" "envoy_alb_service" {
  manifest = yamldecode(file("./manifests/envoy-alb-service.yaml"))

  depends_on = [
    kubernetes_manifest.envoy_gateway,
  ]
}

# alb ingress forwarding to envoy gateway service
resource "kubernetes_manifest" "envoy_alb_ingress" {
  manifest = yamldecode(file("./manifests/envoy-alb-ingress.yaml"))

  depends_on = [
    kubernetes_manifest.envoy_alb_service,
  ]
}

# ns
resource "kubernetes_namespace_v1" "test_app_ns" {
  metadata {
    name = "envoy-test-app"
    labels = {
      "pod-security.kubernetes.io/enforce" = "restricted"
    }
  }
}

# deployment
resource "kubernetes_manifest" "test_deployment" {
  manifest = yamldecode(file("./manifests/deployment.yml"))

  depends_on = [
    kubernetes_namespace_v1.test_app_ns,
  ]
}

# service
resource "kubernetes_manifest" "test_service" {
  manifest = yamldecode(file("./manifests/service.yml"))

  depends_on = [
    kubernetes_namespace_v1.test_app_ns,
    kubernetes_manifest.test_deployment,
  ]
}

# service (alb test route)
resource "kubernetes_manifest" "test_http_route_alb" {
  manifest = yamldecode(file("./manifests/http-route-alb.yaml"))

  depends_on = [
    kubernetes_namespace_v1.test_app_ns,
    kubernetes_manifest.envoy_gateway,
    kubernetes_manifest.test_service,
  ]
}

