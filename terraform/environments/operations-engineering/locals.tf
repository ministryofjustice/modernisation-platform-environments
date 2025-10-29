#### This file can be used to store locals specific to the member account ####
locals {
  oidc_provider = "token.actions.githubusercontent.com"
  account_id    = local.environment_management.account_ids[terraform.workspace]
  aws_region    = data.aws_region.current.name
}


