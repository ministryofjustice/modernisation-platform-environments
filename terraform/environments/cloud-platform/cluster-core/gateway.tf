# Just the envoy gateway installation
module "gateway_api" {
  source           = "./modules/gateway_api"
  wildcard_domain  = "*.${local.cluster_name}.${local.cluster_base_domain}"

  depends_on = [module.lbc]
}

module "lbc" {
  source       = "./modules/lbc"
  cluster_name = local.cluster_name
}

# Lookup Route53 zone for cert-manager ACME DNS challenges
data "aws_route53_zone" "environment" {
  name = local.cluster_base_domain
}

# Cluster wildcard certificate
module "cert_manager" {
  source           = "./modules/cert_manager"
  cluster_name     = local.cluster_name
  route53_zone_id  = data.aws_route53_zone.environment.zone_id
}

