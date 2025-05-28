
module "certs" {
  source = "./modules/dns/certs"

  project_name = local.project_name

  r53_zone_id    = module.public_dns_zone.aws_route53_zone_id
  domain_name    = "yjaf.${local.application_data.accounts[local.environment].domain_name}"
  validate_certs = local.application_data.accounts[local.environment].validate_certs

  tags = local.tags
}
