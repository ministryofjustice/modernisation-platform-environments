##
# Modules for each environment 
# Separate per environment to allow different versions
##
module "environment_dev" {
  # We're in dev account and dev environment, could reference different version
  source = "./modules/environment_all_components"
  count  = local.environment == "development" ? 1 : 0

  providers = {
    aws.bucket-replication    = aws
    aws.core-vpc              = aws.core-vpc
    aws.core-network-services = aws.core-network-services
  }

  env_name      = "dev"
  app_name      = local.application_name
  platform_vars = local.platform_vars

  account_config     = local.account_config_dev
  environment_config = local.environment_config_dev
  ldap_config        = local.ldap_config_dev
  db_config          = local.db_config_dev
  weblogic_config    = local.weblogic_config_dev
  bastion            = local.bastion

  account_info = local.account_info

  tags = local.tags
}

# module "environment_dev2" {
#   #  We're in dev account and dev2 environment, could reference different version
#   source = "./modules/environment_all_components"
#   count  = local.environment == "development" ? 1 : 0

#   providers = {
#     aws.bucket-replication    = aws
#     aws.core-vpc              = aws.core-vpc
#     aws.core-network-services = aws.core-network-services
#   }

#   env_name      = "dev2"
#   app_name      = local.application_name
#   platform_vars = local.platform_vars

#   account_config     = local.account_config_dev
#   environment_config = local.environment_config_dev
#   ldap_config        = local.ldap_config_dev
#   db_config          = local.db_config_dev
#   weblogic_config    = local.weblogic_config_dev
#   bastion            = local.bastion

#   account_info = local.account_info

#   tags = local.tags
# }
