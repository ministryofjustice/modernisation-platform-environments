module "ses" {
  source                = "./modules/ses"
  project_name          = local.project_name
  environment           = local.environment
  tags                  = local.tags
  ses_domain_identities = local.application_data.accounts[local.environment].ses_domain_identities
  key_id                = module.kms.key_id
  private_subnets       = local.private_subnet_list[*].cidr_block

  depends_on = [
    module.justice_public_dns_zone,
    module.justice_public_dns_zone
  ]
}
