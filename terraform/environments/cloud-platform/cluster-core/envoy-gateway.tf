module "envoy-gateway" {
    source = "./modules/envoy-gateway"
    
    cluster_name        = local.cluster_name
    cluster_base_domain = "${local.cluster_name}.development.container-platform.service.justice.gov.uk"
    envoy_proxy_name     = "shared-nlb-proxy"
    envoy_proxy_replicas = 3
    gateway_class_name   = "default-gateway-class"
    gateway_name         = "default"
}