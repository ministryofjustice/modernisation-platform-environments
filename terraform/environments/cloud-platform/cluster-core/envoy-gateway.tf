module "envoy-gateway" {
    source = "./modules/envoy-gateway"
    
    gateway_name         = "default"
    cluster_name        = local.cluster_name
    cluster_base_domain = "${local.cluster_name}.development.container-platform.service.justice.gov.uk"
    envoy_proxy_replicas = 3
}