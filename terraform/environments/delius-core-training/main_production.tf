module "environment_prod" {
  source = "./modules/delius_environment"

  providers = {
    aws                        = aws
    aws.bucket-replication     = aws
    aws.core-vpc               = aws.core-vpc
    aws.core-network-services  = aws.core-network-services
    aws.modernisation-platform = aws.modernisation-platform
  }

  env_name      = "prod"
  app_name      = "delius-training"
  platform_vars = local.platform_vars

  account_config = local.account_config
  account_info   = local.account_info

  environment_config = local.environment_config_prod
  # environments_in_account = local.delius_environments_per_account.prod

  bastion_config = local.bastion_config_prod

  ldap_config        = local.ldap_config_prod
  db_config          = local.db_config_prod
  create_backup_role = true

  delius_microservice_configs = local.delius_microservices_configs_prod

  tags = local.tags

  pagerduty_integration_key = local.pagerduty_integration_key

  dms_config = local.dms_config_prod

  env_name_to_dms_config_map = local.env_name_to_dms_config_map
}
