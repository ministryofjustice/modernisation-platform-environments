##
# Modules for each environment 
# Separate per environment to allow different versions
##
module "environment_dev1" {
  # We're in dev account and dev environment, could reference different version
  source = "./modules/environment_all_components"
  count  = local.environment == "development" ? 1 : 0

  name = "dev1"

  ldap_config = local.ldap_config_dev1
  db_config   = local.db_config_dev1

  account_info = local.account_info
}

module "environment_dev2" {
  # We're in dev account and dev environment, could reference different version
  source = "./modules/environment_all_components"
  count  = local.environment == "development" ? 1 : 0

  name        = "dev2"
  ldap_config = local.ldap_config_dev2
  db_config   = local.db_config_dev2

  account_info = local.account_info
}
