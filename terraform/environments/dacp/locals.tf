#### This file can be used to store locals specific to the member account ####
locals {
  # create name, record,type for monitoring lb aka dacp_lb
  domain_types = { for dvo in aws_acm_certificate.external.domain_validation_options : dvo.domain_name => {
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

  # RDS parameter group family, e.g. "postgres16", built from the engine and its major version so a major
  # upgrade only needs engine_version changing in application_variables.json. Taking the part before the
  # first "." means engine_version can be a major version ("16") or a full one ("16.15").
  db_parameter_group_family = "${local.application_data.accounts[local.environment].engine}${split(".", local.application_data.accounts[local.environment].engine_version)[0]}"
}