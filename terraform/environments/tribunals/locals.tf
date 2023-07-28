#### This file can be used to store locals specific to the member account ####
locals {
  # create name, record,type for monitoring lb aka tribunals_lb
  #transport
  # transport_domain_types = { for dvo in aws_acm_certificate.transport_external.domain_validation_options : dvo.domain_name => {
  #   name   = dvo.resource_record_name
  #   record = dvo.resource_record_value
  #   type   = dvo.resource_record_type
  #   }
  # }

  # transport_domain_name_main   = [for k, v in local.transport_domain_types : v.name if k == "modernisation-platform.service.justice.gov.uk"]
  # transport_domain_name_sub    = [for k, v in local.transport_domain_types : v.name if k != "modernisation-platform.service.justice.gov.uk"]
  # transport_domain_record_main = [for k, v in local.transport_domain_types : v.record if k == "modernisation-platform.service.justice.gov.uk"]
  # transport_domain_record_sub  = [for k, v in local.transport_domain_types : v.record if k != "modernisation-platform.service.justice.gov.uk"]
  # transport_domain_type_main   = [for k, v in local.transport_domain_types : v.type if k == "modernisation-platform.service.justice.gov.uk"]
  # transport_domain_type_sub    = [for k, v in local.transport_domain_types : v.type if k != "modernisation-platform.service.justice.gov.uk"]


  #lands chamber
  lands_domain_types = { for dvo in aws_acm_certificate.lands_external.domain_validation_options : dvo.domain_name => {
    name   = dvo.resource_record_name
    record = dvo.resource_record_value
    type   = dvo.resource_record_type
    }
  }

  lands_domain_name_main   = [for k, v in local.lands_domain_types : v.name if k == "modernisation-platform.service.justice.gov.uk"]
  lands_domain_name_sub    = [for k, v in local.lands_domain_types : v.name if k != "modernisation-platform.service.justice.gov.uk"]
  lands_domain_record_main = [for k, v in local.lands_domain_types : v.record if k == "modernisation-platform.service.justice.gov.uk"]
  lands_domain_record_sub  = [for k, v in local.lands_domain_types : v.record if k != "modernisation-platform.service.justice.gov.uk"]
  lands_domain_type_main   = [for k, v in local.lands_domain_types : v.type if k == "modernisation-platform.service.justice.gov.uk"]
  lands_domain_type_sub    = [for k, v in local.lands_domain_types : v.type if k != "modernisation-platform.service.justice.gov.uk"]


  #administrative appeals
  appeals_domain_types = { for dvo in aws_acm_certificate.appeals_external.domain_validation_options : dvo.domain_name => {
    name   = dvo.resource_record_name
    record = dvo.resource_record_value
    type   = dvo.resource_record_type
    }
  }

  appeals_domain_name_main   = [for k, v in local.appeals_domain_types : v.name if k == "modernisation-platform.service.justice.gov.uk"]
  appeals_domain_name_sub    = [for k, v in local.appeals_domain_types : v.name if k != "modernisation-platform.service.justice.gov.uk"]
  appeals_domain_record_main = [for k, v in local.appeals_domain_types : v.record if k == "modernisation-platform.service.justice.gov.uk"]
  appeals_domain_record_sub  = [for k, v in local.appeals_domain_types : v.record if k != "modernisation-platform.service.justice.gov.uk"]
  appeals_domain_type_main   = [for k, v in local.appeals_domain_types : v.type if k == "modernisation-platform.service.justice.gov.uk"]
  appeals_domain_type_sub    = [for k, v in local.appeals_domain_types : v.type if k != "modernisation-platform.service.justice.gov.uk"]

  #care standards
  cares_domain_types = { for dvo in aws_acm_certificate.cares_external.domain_validation_options : dvo.domain_name => {
    name   = dvo.resource_record_name
    record = dvo.resource_record_value
    type   = dvo.resource_record_type
    }
  }

  cares_domain_name_main   = [for k, v in local.cares_domain_types : v.name if k == "modernisation-platform.service.justice.gov.uk"]
  cares_domain_name_sub    = [for k, v in local.cares_domain_types : v.name if k != "modernisation-platform.service.justice.gov.uk"]
  cares_domain_record_main = [for k, v in local.cares_domain_types : v.record if k == "modernisation-platform.service.justice.gov.uk"]
  cares_domain_record_sub  = [for k, v in local.cares_domain_types : v.record if k != "modernisation-platform.service.justice.gov.uk"]
  cares_domain_type_main   = [for k, v in local.cares_domain_types : v.type if k == "modernisation-platform.service.justice.gov.uk"]
  cares_domain_type_sub    = [for k, v in local.cares_domain_types : v.type if k != "modernisation-platform.service.justice.gov.uk"]

}
