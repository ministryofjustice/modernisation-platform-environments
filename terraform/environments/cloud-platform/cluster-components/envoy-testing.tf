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

# coraza waf policy
resource "kubernetes_manifest" "envoy_waf_policy" {
  manifest = yamldecode(file("./manifests/envoy-extension-policy.yaml"))

  depends_on = [
    kubernetes_manifest.envoy_gateway,
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

# route
resource "kubernetes_manifest" "test_http_route" {
  manifest = yamldecode(file("./manifests/http-route.yml"))

  depends_on = [
    kubernetes_namespace_v1.test_app_ns,
    kubernetes_manifest.envoy_gateway,
    kubernetes_manifest.test_service,
    kubernetes_manifest.envoy_waf_policy,
  ]
}

