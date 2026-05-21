resource "kubectl_manifest" "internet_facing_proxy" {
  yaml_body = file("${path.module}/envoy_manifests/internet-facing-proxy.yaml")
}

resource "kubectl_manifest" "gateway_class_example" {
  yaml_body = file("${path.module}/envoy_manifests/gateway-class-example.yaml")
}



resource "kubernetes_namespace_v1" "ky_test_namespace" {
  metadata {
    name = "ky-test"

    labels = {
      "name"                                            = "ky-test"
      "pod-security.kubernetes.io/enforce"              = "restricted"
    }
  }
}

resource "kubectl_manifest" "app_backend_example" {
  yaml_body = file("${path.module}/envoy_manifests/app_backend_example.yaml")

  depends_on = [ kubernetes_namespace_v1.ky_test_namespace ]
}

resource "kubectl_manifest" "app_backend_example_service" {
  yaml_body = file("${path.module}/envoy_manifests/app_backend_example_service.yaml")

  depends_on = [ kubernetes_namespace_v1.ky_test_namespace ]
}

resource "kubectl_manifest" "app_frontend_example" {
  yaml_body = file("${path.module}/envoy_manifests/app_frontend_example.yaml")

  depends_on = [ kubernetes_namespace_v1.ky_test_namespace ]
}

resource "kubectl_manifest" "app_frontend_example_service" {
  yaml_body = file("${path.module}/envoy_manifests/app_frontend_example_service.yaml")

  depends_on = [ kubernetes_namespace_v1.ky_test_namespace ]
}

resource "kubectl_manifest" "gateway_example" {
  yaml_body = file("${path.module}/envoy_manifests/gateway-example.yaml")

  depends_on = [ helm_release.envoy-gateway ]
}

resource "kubectl_manifest" "app_backend_example_httproute" {
  yaml_body = file("${path.module}/envoy_manifests/app_backend_example_httproute.yaml")
}

resource "kubectl_manifest" "app_frontend_example_httproute" {
  yaml_body = file("${path.module}/envoy_manifests/app_frontend_example_httproute.yaml")
}

