#### This file can be used to store locals specific to the member account ####
locals {
  project_name = "yjaf"

# Locals from application_variables.json  
  environment_name             = "${local.project_name}-${local.environment}"
}


