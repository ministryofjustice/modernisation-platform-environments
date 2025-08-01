#### This file can be used to store locals specific to the member account ####
locals {

  env_account_id = local.environment_management.account_ids[terraform.workspace]

  prod_environment = "production"
  dev_environment  = "development"

  coat_prod_account_id = "279191903737" #local.environment_management.account_ids["coat-production"] 
  coat_dev_account_id  = "082282578003" #local.environment_management.account_ids["coat-development"]

  mp_dev_role = "AWSReservedSSO_modernisation-platform-developer_cd1b8f85b1611d20"

  kms_dev_key_id = "arn:aws:kms:${data.aws_region.current.name}:${local.coat_dev_account_id}:key/b6c2960d-bc58-4fec-b941-ab8e602269ef"

  oidc_provider = "token.actions.githubusercontent.com"

}
