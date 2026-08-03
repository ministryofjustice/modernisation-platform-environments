# Gateway resources (Gateway, GatewayClass, ListenerSet, etc)
module "gateway_api" {
  source = "github.com/ministryofjustice/container-platform-terraform-gateway-api?ref=33be8f18154b51efcbcc2493020ac74384f80462" #1.0.0

  lb_name_prefix      = local.workspace_slug
  cluster_base_domain = local.cluster_domain

  gateway_name         = "default"
  envoy_proxy_replicas = 3
}