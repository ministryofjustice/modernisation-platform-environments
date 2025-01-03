module "public_dns_zone" {
  source              = "./modules/dns/hosted_zone"
  domain_name         = "${local.environment}.yjbservices.yjb.gov.uk"
  project_name        = local.project_name
  private_hosted_zone = false
  vpc                 = data.aws_vpc.shared.id
  tags                = local.tags
}
