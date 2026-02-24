module "kyverno_namespace" {
  source = "./modules/kubernetes/namespace"

  name = "kyverno-system"
}
