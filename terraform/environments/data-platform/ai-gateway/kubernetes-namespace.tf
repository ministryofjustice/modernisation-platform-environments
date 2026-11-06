module "ai_gateway_namespace" {
  source = "../cluster/modules/kubernetes/namespace"

  name              = local.component_name
  workload          = "application"
  pod_security_mode = "restricted"
}

moved {
  from = kubernetes_namespace_v1.ai_gateway
  to   = module.ai_gateway_namespace.kubernetes_namespace_v1.this
}
