#### This file can be used to store locals specific to the member account ####
locals {
  project_name     = "yjaf"
  environment_name = "${local.project_name}-${local.environment}"

  # Locals from application_variables.json  
  test_mode = local.application_data.accounts[local.environment].test_mode
}


