#### This file can be used to store locals specific to the member account ####
locals {
  # create name, record,type for monitoring lb aka tipstaff_dev_lb
  tipstaff_domain_types = { for dvo in aws_acm_certificate.inner.domain_validation_options : dvo.domain_name => {
    name   = dvo.resource_record_name
    record = dvo.resource_record_value
    type   = dvo.resource_record_type
    }
  }

  tipstaff_domain_name_main   = [for k, v in local.tipstaff_domain_types : v.name if k == "modernisation-platform.service.justice.gov.uk"]
  tipstaff_domain_name_sub    = [for k, v in local.tipstaff_domain_types : v.name if k != "modernisation-platform.service.justice.gov.uk"]
  tipstaff_domain_record_main = [for k, v in local.tipstaff_domain_types : v.record if k == "modernisation-platform.service.justice.gov.uk"]
  tipstaff_domain_record_sub  = [for k, v in local.tipstaff_domain_types : v.record if k != "modernisation-platform.service.justice.gov.uk"]
  tipstaff_domain_type_main   = [for k, v in local.tipstaff_domain_types : v.type if k == "modernisation-platform.service.justice.gov.uk"]
  tipstaff_domain_type_sub    = [for k, v in local.tipstaff_domain_types : v.type if k != "modernisation-platform.service.justice.gov.uk"]

}