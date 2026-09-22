# Gateway resources (Gateway, GatewayClass, ListenerSet, etc)
module "gateway_api" {
  source = "github.com/ministryofjustice/container-platform-terraform-gateway-api?ref=69b02bfb20caa831f1ba106df924f611e054fd9a" #1.3.0

  lb_name_prefix      = local.workspace_slug
  cluster_base_domain = local.cluster_domain

  gateway_name         = "default"
  envoy_proxy_replicas = 3

  enable_owasp = true
}
