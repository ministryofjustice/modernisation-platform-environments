#### This file can be used to store locals specific to the member account ####
locals {
  env_account_id = local.environment_management.account_ids[terraform.workspace]
}
