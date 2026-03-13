locals {
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

  prometheus_operator_crds = [
    "alertmanagerconfigs",
    "alertmanagers",
    "podmonitors",
    "probes",
    "prometheusagents",
    "prometheuses",
    "prometheusrules",
    "scrapeconfigs",
    "servicemonitors",
    "thanosrulers"
  ]
}

data "http" "gateway_api_crd" {
  for_each = toset(local.gateway_api_crds)

  url = "https://raw.githubusercontent.com/kubernetes-sigs/gateway-api/${local.cluster_configuration.crd_versions.gateway_api}/config/crd/standard/gateway.networking.k8s.io_${each.key}.yaml"
}

resource "kubernetes_manifest" "gateway_api_crd" {
  for_each = local.gateway_api_manifests

  manifest = each.value
}

data "http" "prometheus_operator_crds" {
  for_each = toset(local.prometheus_operator_crds)

  url = "https://raw.githubusercontent.com/prometheus-operator/prometheus-operator/${local.cluster_configuration.crd_versions.prometheus}/example/prometheus-operator-crd/monitoring.coreos.com_${each.key}.yaml"
}

resource "kubernetes_manifest" "prometheus_operator_crd" {
  for_each = data.http.prometheus_operator_crds

  manifest = yamldecode(each.value.response_body)
}
