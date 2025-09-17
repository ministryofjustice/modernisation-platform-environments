##
# Modules for each environment 
# Separate per environment to allow different versions
##

module "environment_stage" {
  #  We're in preproduction account and stage environment
  source = "./modules/delius_environment"
  count  = local.is-preproduction ? 1 : 0

  providers = {
    aws                        = aws
    aws.bucket-replication     = aws
    aws.core-vpc               = aws.core-vpc
    aws.core-network-services  = aws.core-network-services
    aws.modernisation-platform = aws.modernisation-platform
  }

  env_name      = "stage"
  app_name      = local.application_name
  platform_vars = local.platform_vars

  account_config = local.account_config
  account_info   = local.account_info

  environment_config      = local.environment_config_stage
  environments_in_account = local.delius_environments_per_account.pre_prod

  bastion_config = local.bastion_config_stage

  ldap_config        = local.ldap_config_stage
  db_config          = local.db_config_stage
  create_backup_role = false
  create_ecs_lambda  = false

  delius_microservice_configs = local.delius_microservices_configs_stage

  tags = local.tags

  pagerduty_integration_key = local.pagerduty_integration_key

  dms_config = local.dms_config_stage

  env_name_to_dms_config_map = local.env_name_to_dms_config_map
}

module "environment_preprod" {
  #  We're in preproduction account and pre-prod environment
  source = "./modules/delius_environment"
  count  = local.is-preproduction ? 1 : 0

  providers = {
    aws                        = aws
    aws.bucket-replication     = aws
    aws.core-vpc               = aws.core-vpc
    aws.core-network-services  = aws.core-network-services
    aws.modernisation-platform = aws.modernisation-platform
  }

  env_name      = "preprod"
  app_name      = local.application_name
  platform_vars = local.platform_vars

  account_config = local.account_config
  account_info   = local.account_info

  environment_config      = local.environment_config_preprod
  environments_in_account = local.delius_environments_per_account.pre_prod

  bastion_config = local.bastion_config_preprod

  ldap_config        = local.ldap_config_preprod
  db_config          = local.db_config_preprod
  create_backup_role = true
  create_ecs_lambda  = true

  delius_microservice_configs = local.delius_microservices_configs_preprod

  tags = local.tags

  pagerduty_integration_key = local.pagerduty_integration_key

  dms_config = local.dms_config_preprod

  env_name_to_dms_config_map = local.env_name_to_dms_config_map
}
