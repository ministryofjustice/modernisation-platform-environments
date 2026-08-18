# Gateway resources (Gateway, GatewayClass, ListenerSet, etc)
module "gateway_api" {
  source = "github.com/ministryofjustice/container-platform-terraform-gateway-api?ref=843e089f33b6e7b922cd3ad434ea52e0d20ff721" #1.2.0

  lb_name_prefix      = local.workspace_slug
  cluster_base_domain = local.cluster_domain

  gateway_name         = "default"
  envoy_proxy_replicas = 3

  enable_owasp = true
}