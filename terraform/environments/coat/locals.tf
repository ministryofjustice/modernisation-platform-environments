#### This file can be used to store locals specific to the member account ####
locals {

  env_account_id = local.environment_management.account_ids[terraform.workspace]

  prod_environment     = "production"
  dev_environment      = "development"
  coat_prod_account_id = "279191903737" #local.environment_management.account_ids["coat-production"] 
  coat_dev_account_id  = "082282578003" #local.environment_management.account_ids["coat-development"]

  cross_environment = substr(terraform.workspace, length(local.application_name), length(terraform.workspace)) == "-production" ? local.dev_environment : local.prod_environment

  cross_env_account_id = substr(terraform.workspace, length(local.application_name), length(terraform.workspace)) == "-production" ? local.coat_dev_account_id : local.coat_prod_account_id

}
