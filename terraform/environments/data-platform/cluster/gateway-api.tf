locals {
  gateway_api_version = "v1.4.1" # https://docs.cilium.io/en/v1.19/network/servicemesh/gateway-api/gateway-api/#cilium-gateway-api-support

  gateway_api_crds = [
    "gatewayclasses",
    "gateways",
    "httproutes",
    "referencegrants",
    "grpcroutes"
  ]

  # Filter out 'status' field from manifests as kubernetes_manifest resource
  # does not allow it (Kubernetes manages status fields itself)
  gateway_api_manifests = {
    for key, crd in data.http.gateway_api_crd :
    key => {
      for k, v in yamldecode(crd.response_body) :
      k => v if k != "status"
    }
  }
}

data "http" "gateway_api_crd" {
  for_each = toset(local.gateway_api_crds)

  url = "https://raw.githubusercontent.com/kubernetes-sigs/gateway-api/${local.gateway_api_version}/config/crd/standard/gateway.networking.k8s.io_${each.key}.yaml"
}

resource "kubernetes_manifest" "gateway_api_crd" {
  for_each = local.gateway_api_manifests

  manifest = each.value
}
