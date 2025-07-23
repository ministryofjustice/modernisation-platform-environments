#### This file can be used to store locals specific to the member account ####
locals {
  project_name     = "yjaf"
  environment_name = "${local.project_name}-${local.environment}"

  account_id = data.aws_caller_identity.current.account_id

  # Locals from application_variables.json  
  test_mode = local.application_data.accounts[local.environment].test_mode
}

## Locals for the YJB Data Scientist Team access ##
locals {
  yjb_data_scientist_role_name = "data-scientist"
}

