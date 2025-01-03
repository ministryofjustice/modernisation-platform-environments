module "private_dns_zone" {
  source              = "./modules/dns/hosted_zone"
  domain_name         = "${local.environment}.yjaf"
  project_name        = local.project_name
  private_hosted_zone = true
  vpc                 = data.aws_vpc.shared.id
  tags                = local.tags
}
