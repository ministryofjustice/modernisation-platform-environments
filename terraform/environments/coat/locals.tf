#### This file can be used to store locals specific to the member account ####
locals {
  prod_environment  = "production"
  dev_environment   = "development"
  cross_environment = substr(terraform.workspace, length(local.application_name), length(terraform.workspace)) == "-production" ? local.dev_environment : local.prod_environment
}
