#### This file can be used to store locals specific to the member account ####
locals {

  env_account_id = local.environment_management.account_ids[terraform.workspace]

  prod_environment = "production"
  dev_environment  = "development"

  coat_prod_account_id = "279191903737" #local.environment_management.account_ids["coat-production"] 
  coat_dev_account_id  = "082282578003" #local.environment_management.account_ids["coat-development"]

  mp_dev_role = "AWSReservedSSO_modernisation-platform-developer_cd1b8f85b1611d20"

}
