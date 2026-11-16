module "app_namespace" {
  source = "../cluster/modules/kubernetes/namespace"

  name              = local.component_name
  workload          = "application"
  pod_security_mode = "restricted"
}
