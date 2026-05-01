module "kyverno_namespace" {
  source = "./modules/kubernetes/namespace"

  name     = "kyverno"
  workload = "system"
}

module "cluster_autoscaler_namespace" {
  source = "./modules/kubernetes/namespace"

  name     = "cluster-autoscaler"
  workload = "system"
}

module "aws_cloudwatch_observability_namespace" {
  source = "./modules/kubernetes/namespace"

  name     = "aws-cloudwatch-observability"
  workload = "system"
}

module "prometheus_namespace" {
  source = "./modules/kubernetes/namespace"

  name     = "prometheus"
  workload = "system"
}

module "fluent_bit_namespace" {
  source = "./modules/kubernetes/namespace"

  name     = "fluent-bit"
  workload = "system"
}

module "cert_manager_namespace" {
  source = "./modules/kubernetes/namespace"

  name     = "cert-manager"
  workload = "system"
}

module "karpenter_namespace" {
  source = "./modules/kubernetes/namespace"

  name     = "karpenter"
  workload = "system"
}

module "external_dns_namespace" {
  source = "./modules/kubernetes/namespace"

  name     = "external-dns"
  workload = "system"
}

module "external_secrets_namespace" {
  source = "./modules/kubernetes/namespace"

  name     = "external-secrets"
  workload = "system"
}

module "shared_services_namespace" {
  source = "./modules/kubernetes/namespace"

  name     = "shared-services"
  workload = "system"
}

module "keda_namespace" {
  source = "./modules/kubernetes/namespace"

  name     = "keda"
  workload = "system"
}
