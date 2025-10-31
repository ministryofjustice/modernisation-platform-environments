#### This file can be used to store locals specific to the member account ####
locals {
  project_name     = "yjaf"
  environment_name = "${local.project_name}-${local.environment}"

  account_id = data.aws_caller_identity.current.account_id

  # Locals from application_variables.json  
  test_mode = local.application_data.accounts[local.environment].test_mode
}

## Locals for the report admin and YJB Data Scientist Team access ##
locals {
  reports_admin_role_name      = "reporting-operations"
  yjb_data_scientist_role_name = "data-scientist"
}

