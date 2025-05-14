# ##
# # Modules for each environment 
# # Separate per environment to allow different versions
# ##

module "environment_poc" {
  # We're in dev account and poc environment, could reference different version
  source = "./modules/alfresco"
  count  = local.is-development ? 1 : 0

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

  ldap_config                = local.ldap_config_poc
  ldap_formatted_error_codes = local.ldap_formatted_error_codes

  delius_microservice_configs = local.delius_microservices_configs_poc

  tags = local.tags
}
