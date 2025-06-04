
module "public_dns_zone" {
  source              = "./modules/dns/hosted_zone"
  domain_name         = local.application_data.accounts[local.environment].domain_name
  project_name        = local.project_name
  private_hosted_zone = false
  vpc                 = data.aws_vpc.shared.id
  tags                = local.tags
}

#used only for ses
module "justice_public_dns_zone" {
  source              = "./modules/dns/hosted_zone"
  domain_name         = local.application_data.accounts[local.environment].justice_domain_name
  project_name        = local.project_name
  private_hosted_zone = false
  vpc                 = data.aws_vpc.shared.id
  tags                = local.tags
}

