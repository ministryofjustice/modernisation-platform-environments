data "http" "envoy_install_manifest" {
  url = "https://github.com/envoyproxy/gateway/releases/download/v1.8.0/install.yaml"
}

locals {
  envoy_install_docs = {
    for doc in [
      for doc in split("\n---\n", data.http.envoy_install_manifest.response_body) : yamldecode(doc)
      if can(yamldecode(doc)) && yamldecode(doc) != null && length(regexall("kind:", doc)) > 0 && try(yamldecode(doc).kind, "") != "Namespace"
    ] : sha1(yamlencode(doc)) => yamlencode(doc)
  }
}

resource "kubernetes_namespace_v1" "envoy_gateway_system" {
  metadata {
    name = "envoy-gateway-system"
    annotations = {
      "container-platform.justice.gov.uk/can-use-loadbalancer-services" = "true"
    }
    labels = {
      "pod-security.kubernetes.io/enforce" = "restricted"
    }
  }
}

resource "kubectl_manifest" "envoy_gateway_install" {
  for_each   = local.envoy_install_docs
  depends_on = [kubernetes_namespace_v1.envoy_gateway_system]

  yaml_body         = each.value
  server_side_apply = true
  wait              = true
}
