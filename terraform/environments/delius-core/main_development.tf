##
# Modules for each environment 
# Separate per environment to allow different versions
##
module "environment_dev" {
  # We're in dev account and dev environment, could reference different version
  source = "./modules/delius_environment"
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

  account_config = local.account_config
  account_info   = local.account_info

  environment_config      = local.environment_config_dev
  environments_in_account = local.delius_environments_per_account.dev

  bastion_config = local.bastion_config_dev

  ldap_config = local.ldap_config_dev
  db_config   = local.db_config_dev

  delius_microservice_configs = local.delius_microservices_configs_dev

  tags = local.tags

  pagerduty_integration_key = local.pagerduty_integration_key

  dms_config = merge(local.dms_config_dev, { client_account_arns = local.dms_client_account_arns })

}
