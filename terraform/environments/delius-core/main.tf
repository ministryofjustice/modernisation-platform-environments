##
# Single module driven for all data
##
# module "account_all_components" {
#   source = "./modules/account_all_components?"

#   ec2_instances           = lookup(local.account_config, "ec2_instances", {})
#   account_config_baseline = local.account_config_baseline

#   account = {
#     vpc_id = data.aws_vpc.shared.id
#   }
# }

##
# Modules for each environment 
# Separate per environment to allow different versions
##
module "environment_dev1" {
  # We're in dev account and dev environment, could reference different version
  source = "./modules/environment_all_components"
  count  = local.environment == "development" ? 1 : 0

  name = "dev1"

  ldap = {}

  account = {
    vpc_id = data.aws_vpc.shared.id
  }
}

module "environment_dev2" {
  # We're in dev account and dev environment, could reference different version
  source = "./modules/environment_all_components"
  count  = local.environment == "development" ? 1 : 0

  name = "dev2"

  account = {
    vpc_id = data.aws_vpc.shared.id
  }
}
