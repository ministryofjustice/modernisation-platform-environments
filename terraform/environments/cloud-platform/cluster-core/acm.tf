module "acm" {
  source = "./modules/acm"

  cluster_name        = local.cluster_name
  cluster_environment = local.cluster_environment
  gateway_name        = module.envoy-gateway.gateway_name
}