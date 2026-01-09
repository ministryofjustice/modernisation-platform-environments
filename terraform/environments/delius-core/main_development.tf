##
# Modules for each environment 
# Separate per environment to allow different versions
##
module "environment_dev" {
  # We're in dev account and dev environment, could reference different version
  source = "./modules/delius_environment"
  count  = local.is-development ? 1 : 0

  providers = {
    aws                        = aws
    aws.bucket-replication     = aws
    aws.core-vpc               = aws.core-vpc
    aws.core-network-services  = aws.core-network-services
    aws.modernisation-platform = aws.modernisation-platform
  }

  env_name      = "dev"
  app_name      = local.application_name
  platform_vars = local.platform_vars

  account_config = local.account_config
  account_info   = local.account_info

  environment_config      = local.environment_config_dev
  environments_in_account = local.delius_environments_per_account.dev

  bastion_config = local.bastion_config_dev

  ldap_config        = local.ldap_config_dev
  db_config          = local.db_config_dev
  create_backup_role = true
  create_ecs_lambda  = true

  delius_microservice_configs = local.delius_microservices_configs_dev

  tags = local.tags

  pagerduty_integration_key = local.pagerduty_integration_key

  dms_config = local.dms_config_dev

  env_name_to_dms_config_map = local.env_name_to_dms_config_map
}

module "environment_poc" {
  # We're in dev account and poc environment, could reference different version
  source = "./modules/delius_environment"
  count  = 0

  providers = {
    aws                        = aws
    aws.bucket-replication     = aws
    aws.core-vpc               = aws.core-vpc
    aws.core-network-services  = aws.core-network-services
    aws.modernisation-platform = aws.modernisation-platform
  }

  env_name      = "poc"
  app_name      = local.application_name
  platform_vars = local.platform_vars

  account_config = local.account_config
  account_info   = local.account_info

  environment_config      = local.environment_config_poc
  environments_in_account = local.delius_environments_per_account.dev

  bastion_config = local.bastion_config_poc

  ldap_config        = local.ldap_config_poc
  db_config          = local.db_config_poc
  create_backup_role = false
  create_ecs_lambda  = false

  delius_microservice_configs = local.delius_microservices_configs_poc

  tags = local.tags

  pagerduty_integration_key = local.pagerduty_integration_key

  dms_config = local.dms_config_poc

  env_name_to_dms_config_map = local.env_name_to_dms_config_map
}
