module "kyverno_namespace" {
  source = "./modules/kubernetes/namespace"

  name = "kyverno-system"
}

module "cluster_autoscaler_namespace" {
  source = "./modules/kubernetes/namespace"

  name = "cluster-autoscaler"
}

module "prometheus_namespace" {
  source = "./modules/kubernetes/namespace"

  name = "prometheus"
}

module "fluent_bit_namespace" {
  source = "./modules/kubernetes/namespace"

  name = "fluent-bit"
}

module "cert_manager_namespace" {
  source = "./modules/kubernetes/namespace"

  name = "cert-manager"
}

module "karpenter_namespace" {
  source = "./modules/kubernetes/namespace"

  name = "karpenter"
}


module "external_dns_namespace" {
  source = "./modules/kubernetes/namespace"

  name = "external-dns"
}

module "shared_services_namespace" {
  source = "./modules/kubernetes/namespace"

  name = "shared-services"
}
