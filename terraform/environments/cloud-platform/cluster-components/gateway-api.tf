# Gateway resources (Gateway, GatewayClass, ListenerSet, etc)
module "gateway_api" {
  source = "github.com/ministryofjustice/container-platform-terraform-gateway-api?ref=0b3f22ccaa99ade027b88c9c4ea83f7f9a4e2b80" #1.4.1

  lb_name_prefix      = local.workspace_slug
  cluster_base_domain = local.cluster_domain

  gateway_name         = "default"
  envoy_proxy_replicas = 3

  enable_owasp = true
}
