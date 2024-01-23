##
# Modules for each environment 
# Separate per environment to allow different versions
##
module "environment_dev" {
  # We're in dev account and dev environment, could reference different version
  source = "./modules/environment_all_components"
  count  = local.is-development ? 1 : 0

  providers = {
    aws                       = aws
    aws.bucket-replication    = aws
    aws.core-vpc              = aws.core-vpc
    aws.core-network-services = aws.core-network-services
  }

  env_name      = "dev"
  app_name      = local.application_name
  platform_vars = local.platform_vars

  account_config             = local.account_config_dev
  environment_config         = local.environment_config_dev
  ldap_config                = local.ldap_config_dev
  db_config                  = local.db_config_dev
  gdpr_api_config            = local.gdpr_api_config_dev
  weblogic_config            = local.weblogic_config_dev
  delius_db_container_config = local.delius_db_container_config_dev
  bastion_config             = local.bastion_config_dev

  account_info = local.account_info

  environments_in_account = local.delius_environments_per_account.dev

  tags = local.tags
}
