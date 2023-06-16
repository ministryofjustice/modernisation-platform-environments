##
# Modules for each environment 
# Separate per environment to allow different versions
##
module "environment_test1" {
  # We're in dev account and dev environment, could reference different version
  source = "./modules/environment_all_components"
  count  = local.environment == "test" ? 1 : 0

  name = "test1"

  ldap_config = local.ldap_config_dev1
  db_config   = local.db_config_dev1

  account = {
    vpc_id = data.aws_vpc.shared.id
  }
}

module "environment_test2" {
  # We're in dev account and dev environment, could reference different version
  source = "./modules/environment_all_components"
  count  = local.environment == "test" ? 1 : 0

  name        = "test2"
  ldap_config = local.ldap_config_test2
  db_config   = local.db_config_test2

  account = {
    vpc_id = data.aws_vpc.shared.id
  }
}
