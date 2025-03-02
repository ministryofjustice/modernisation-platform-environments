#for_each = var.ses_domain_identities
module "ses" {
  source                = "./modules/ses"
  project_name          = var.project_name
  environment           = var.environment
  tags                  = var.tags
  ses_domain_identities = var.ses_domain_identities
}
