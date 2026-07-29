# Base envoy installation, includes gateway api CRDs
module "envoy_gateway" {
  source = "github.com/ministryofjustice/container-platform-terraform-envoy-gateway?ref=d3bea0e86de00c0ca463084a0e7921fb776fa26e" #1.0.0

  depends_on = [module.gatekeeper]
}

# Gateway resources (Gateway, GatewayClass, ListenerSet, etc)
module "gateway_api" {
  source = "github.com/ministryofjustice/container-platform-terraform-gateway-api?ref=33be8f18154b51efcbcc2493020ac74384f80462" #1.0.0

  lb_name_prefix      = local.workspace_slug
  cluster_base_domain = local.cluster_domain

  gateway_name         = "default"
  envoy_proxy_replicas = 3

  depends_on = [module.envoy_gateway, module.cert_manager, module.external_dns]
}