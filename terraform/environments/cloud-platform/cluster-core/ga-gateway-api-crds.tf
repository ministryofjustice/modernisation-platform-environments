data "http" "gateway_api_crds" {
  url = "https://github.com/kubernetes-sigs/gateway-api/releases/download/v1.5.1/standard-install.yaml"
}

locals {
  gateway_api_crd_docs = {
    for doc in [
      for doc in split("---\n", data.http.gateway_api_crds.response_body) : doc
      if length(regexall("kind:", doc)) > 0
    ] : sha1(doc) => doc
  }
}

resource "kubectl_manifest" "gateway_api_crds" {
  for_each = local.gateway_api_crd_docs

  yaml_body         = each.value
  server_side_apply = true
  wait              = true
}
