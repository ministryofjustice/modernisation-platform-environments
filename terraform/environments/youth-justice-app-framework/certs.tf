
module "certs" {
  source = "./modules/dns/certs"

  project_name = local.project_name

  r53_zone_id = module.public_dns_zone.aws_route53_zone_id
  domain_name = "yjaf.${local.environment}.yjbservices.yjb.gov.uk"

  tags = local.tags
}
