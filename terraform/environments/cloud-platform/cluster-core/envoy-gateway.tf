module "envoy-gateway" {
    source = "./modules/envoy-gateway"
    
    cluster_name        = local.cluster_name
    cluster_base_domain = "${local.cluster_name}.development.container-platform.service.justice.gov.uk"
}