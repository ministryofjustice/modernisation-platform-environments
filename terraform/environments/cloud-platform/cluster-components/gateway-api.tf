# Gateway resources (Gateway, GatewayClass, ListenerSet, etc)
module "gateway_api" {
  source = "github.com/ministryofjustice/container-platform-terraform-gateway-api?ref=085b885fb01575f92ffeee742f11e27116d027b3" #1.1.0

  lb_name_prefix      = local.workspace_slug
  cluster_base_domain = local.cluster_domain

  gateway_name         = "default"
  envoy_proxy_replicas = 3
}