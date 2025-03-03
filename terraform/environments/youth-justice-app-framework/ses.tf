module "ses" {
  for_each              = toset(local.application_data.accounts[local.environment].ses_domain_identities)
  source                = "./modules/ses"
  project_name          = local.project_name
  environment           = local.environment
  tags                  = local.tags
  ses_domain_identities = each.value
  key_id                = module.kms.key_id
}
