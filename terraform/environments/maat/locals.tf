#### This file can be used to store locals specific to the member account ####

locals {
  env_account_id     = local.environment_management.account_ids[terraform.workspace]
  env_account_region = data.aws_region.current.id

  # create name, record,type for monitoring lb aka maat_api_lb
  domain_types = { for dvo in aws_acm_certificate.maat_api_acm_certificate.domain_validation_options : dvo.domain_name => {
    name   = dvo.resource_record_name
    record = dvo.resource_record_value
    type   = dvo.resource_record_type
    }
  }

  domain_name_main   = [for k, v in local.domain_types : v.name if k == "modernisation-platform.service.justice.gov.uk"]
  domain_name_sub    = [for k, v in local.domain_types : v.name if k != "modernisation-platform.service.justice.gov.uk"]
  domain_record_main = [for k, v in local.domain_types : v.record if k == "modernisation-platform.service.justice.gov.uk"]
  domain_record_sub  = [for k, v in local.domain_types : v.record if k != "modernisation-platform.service.justice.gov.uk"]
  domain_type_main   = [for k, v in local.domain_types : v.type if k == "modernisation-platform.service.justice.gov.uk"]
  domain_type_sub    = [for k, v in local.domain_types : v.type if k != "modernisation-platform.service.justice.gov.uk"]

  task_definition = templatefile("td.json", 
    {
    docker_image_tag            = local.application_data.accounts[local.environment].docker_image_tag
    region                      = local.application_data.accounts[local.environment].region
    sentry_env                  = local.environment
    maat_orch_base_url          = local.application_data.accounts[local.environment].maat_orch_base_url
    maat_ccp_base_url           = local.application_data.accounts[local.environment].maat_ccp_base_url
    maat_orch_oauth_url         = local.application_data.accounts[local.environment].maat_orch_oauth_url
    maat_ccc_oauth_url          = local.application_data.accounts[local.environment].maat_ccc_oauth_url
    maat_cma_endpoint_auth_url  = local.application_data.accounts[local.environment].maat_cma_endpoint_auth_url
    maat_ccp_endpoint_auth_url  = local.application_data.accounts[local.environment].maat_ccp_endpoint_auth_url
    maat_db_url                 = local.application_data.accounts[local.environment].maat_db_url
    maat_ccc_base_url           = local.application_data.accounts[local.environment].maat_ccc_base_url
    maat_caa_oauth_url          = local.application_data.accounts[local.environment].maat_caa_oauth_url
    maat_bc_endpoint_url        = local.application_data.accounts[local.environment].maat_bc_endpoint_url
    maat_mlra_url               = local.application_data.accounts[local.environment].maat_mlra_url
    maat_caa_base_url           = local.application_data.accounts[local.environment].maat_caa_base_url
    maat_cma_url                = local.application_data.accounts[local.environment].maat_cma_url
    ecr_url                     = "${local.environment_management.account_ids["core-shared-services-production"]}.dkr.ecr.eu-west-2.amazonaws.com/maat"
    }
  )  
}
