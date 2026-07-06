# Base envoy installation, includes gateway api CRDs
module "envoy_gateway" {
  source = "github.com/ministryofjustice/container-platform-terraform-envoy-gateway?ref=1.0.0"

  depends_on = [module.gatekeeper]
}

# Gateway resources (Gateway, GatewayClass, ListenerSet, etc)
module "gateway_api" {
  source = "github.com/ministryofjustice/container-platform-terraform-gateway-api?ref=6f24df9046546fd0ce88035e2e96da578f7923d0"

  cluster_name        = coalesce(local.cluster_name, terraform.workspace)
  cluster_environment = coalesce(local.cluster_environment, "development_cluster")
  cluster_base_domain = format(
    "%s.development.container-platform.service.justice.gov.uk",
    coalesce(local.cluster_name, terraform.workspace)
  )

  gateway_name = "default"
  envoy_proxy_replicas = 3

  depends_on = [module.envoy_gateway, module.cert_manager, module.external_dns]
}