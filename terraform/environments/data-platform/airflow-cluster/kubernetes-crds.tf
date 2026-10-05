locals {
  gateway_api_crds = [
    "gatewayclasses",
    "gateways",
    "httproutes",
    "listenersets",
    "referencegrants",
    "grpcroutes"
  ]

  # 'status' is stripped because Kubernetes manages status fields itself
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

  prometheus_operator_manifests = {
    for key, crd in data.http.prometheus_operator_crds :
    key => {
      for k, v in yamldecode(crd.response_body) :
      k => v if k != "status"
    }
  }

  # Keyed by CRD name rather than position in the file, so the two AWS Load Balancer
  # Controller files can be merged into one release without their keys colliding
  aws_load_balancer_controller_crd_manifests = {
    for doc in split("\n---\n", data.http.aws_load_balancer_controller_crd.response_body) :
    yamldecode(doc).metadata.name => {
      for k, v in yamldecode(doc) :
      k => v if k != "status"
    }
    if trimspace(doc) != ""
  }

  # gateway.k8s.aws Gateway API CRDs (LoadBalancerConfiguration, TargetGroupConfiguration,
  # ListenerRuleConfiguration) live in a separate file to the rest of the controller's CRDs.
  aws_load_balancer_controller_gateway_crd_manifests = {
    for doc in split("\n---\n", data.http.aws_load_balancer_controller_gateway_crd.response_body) :
    yamldecode(doc).metadata.name => {
      for k, v in yamldecode(doc) :
      k => v if k != "status"
    }
    if trimspace(doc) != ""
  }
}

data "http" "gateway_api_crd" {
  for_each = toset(local.gateway_api_crds)

  url = "https://raw.githubusercontent.com/kubernetes-sigs/gateway-api/${local.cluster_configuration.crd_versions.gateway_api}/config/crd/standard/gateway.networking.k8s.io_${each.key}.yaml"
}

data "http" "prometheus_operator_crds" {
  for_each = toset(local.prometheus_operator_crds)

  url = "https://raw.githubusercontent.com/prometheus-operator/prometheus-operator/${local.cluster_configuration.crd_versions.prometheus}/example/prometheus-operator-crd/monitoring.coreos.com_${each.key}.yaml"
}

data "http" "aws_load_balancer_controller_crd" {
  url = "https://raw.githubusercontent.com/aws/eks-charts/${local.cluster_configuration.crd_versions.aws_load_balancer_controller}/stable/aws-load-balancer-controller/crds/crds.yaml"
}

data "http" "aws_load_balancer_controller_gateway_crd" {
  url = "https://raw.githubusercontent.com/aws/eks-charts/${local.cluster_configuration.crd_versions.aws_load_balancer_controller}/stable/aws-load-balancer-controller/crds/gateway-crds.yaml"
}

resource "terraform_data" "cluster_api_ready" {
  input  = {
   endpoint = module.eks.cluster_endpoint
   access = module.eks.access_policy_associations
  }
}

resource "helm_release" "gateway_api_crds" {
  name      = "gateway-api-crds"
  chart     = "./src/helm/charts/manifests"
  namespace = "kube-system"

  values = [yamlencode({ keep = true, manifests = local.gateway_api_manifests })]

  depends_on = [terraform_data.cluster_api_ready]
}

resource "helm_release" "aws_load_balancer_controller_crds" {
  name      = "aws-load-balancer-controller-crds"
  chart     = "./src/helm/charts/manifests"
  namespace = "kube-system"

  values = [yamlencode({
    keep      = true
    manifests = merge(
      local.aws_load_balancer_controller_crd_manifests,
      local.aws_load_balancer_controller_gateway_crd_manifests
    )
  })]

  depends_on = [terraform_data.cluster_api_ready]
}

resource "helm_release" "prometheus_operator_crd" {
  for_each = local.prometheus_operator_manifests

  name      = "prometheus-operator-crd-${each.key}"
  chart     = "./src/helm/charts/manifests"
  namespace = module.prometheus_namespace.name

  values = [yamlencode({ keep = true, manifests = { (each.key) = each.value } })]

  depends_on = [terraform_data.cluster_api_ready]
}