#### This file can be used to store locals specific to the member account ####
locals {
  # create name, record,type for monitoring lb aka tipstaff_lb
  domain_types = { for dvo in aws_acm_certificate.external.domain_validation_options : dvo.domain_name => {
    name   = dvo.resource_record_name
    record = dvo.resource_record_value
    type   = dvo.resource_record_type
    }
  }

  domain_name_main   = local.is-production ? [for k, v in local.domain_types : v.name if k == "service.justice.gov.uk"] : [for k, v in local.domain_types : v.name if k == "modernisation-platform.service.justice.gov.uk"]
  domain_name_sub    = local.is-production ? [for k, v in local.domain_types : v.name if k != "service.justice.gov.uk"] : [for k, v in local.domain_types : v.name if k != "modernisation-platform.service.justice.gov.uk"]
  domain_record_main = local.is-production ? [for k, v in local.domain_types : v.record if k == "service.justice.gov.uk"] : [for k, v in local.domain_types : v.record if k == "modernisation-platform.service.justice.gov.uk"]
  domain_record_sub  = local.is-production ? [for k, v in local.domain_types : v.record if k != "service.justice.gov.uk"] : [for k, v in local.domain_types : v.record if k != "modernisation-platform.service.justice.gov.uk"]
  domain_type_main   = local.is-production ? [for k, v in local.domain_types : v.type if k == "service.justice.gov.uk"] : [for k, v in local.domain_types : v.type if k == "modernisation-platform.service.justice.gov.uk"]
  domain_type_sub    = local.is-production ? [for k, v in local.domain_types : v.type if k != "service.justice.gov.uk"] : [for k, v in local.domain_types : v.type if k != "modernisation-platform.service.justice.gov.uk"]

}
