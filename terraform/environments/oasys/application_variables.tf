# See oasys-development.tf etc for the environment specific settings
locals {
  accounts = {
    development   = local.oasys_development
    test          = local.oasys_test
    preproduction = local.oasys_preproduction
    production    = local.oasys_production
  }

  account_id         = local.environment_management.account_ids[terraform.workspace]
  environment_config = local.accounts[local.environment]
}
