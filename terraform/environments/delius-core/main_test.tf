##
# Modules for each environment 
# Separate per environment to allow different versions
##

module "environment_test" {
  #  We're in dev account and test environment, could reference different version
  source = "./modules/environment_all_components"
  count  = local.is-test ? 1 : 0

  providers = {
    aws                       = aws
    aws.bucket-replication    = aws
    aws.core-vpc              = aws.core-vpc
    aws.core-network-services = aws.core-network-services
  }

  env_name      = "test"
  app_name      = local.application_name
  platform_vars = local.platform_vars

  account_config      = local.account_config
  environment_config  = local.environment_config_test
  ldap_config         = local.ldap_config_test
  db_config           = local.db_config_test
  weblogic_config     = local.weblogic_config_test
  weblogic_eis_config = local.weblogic_eis_config_test
  merge_config        = local.merge_config_test
  gdpr_config         = local.gdpr_config_test
  bastion_config      = local.bastion_config_test

  account_info = local.account_info

  environments_in_account = local.delius_environments_per_account.test

  tags = local.tags
}