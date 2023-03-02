#### This file can be used to store locals specific to the member account ####

locals {
  region = "eu-west-2"
  vpc_id   = data.aws_vpc.shared.id

  domain_types = { for dvo in aws_acm_certificate.waf_lb_cert.domain_validation_options : dvo.domain_name => {
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

  # create name, record,type for monitoring lb aka prtg_lb
  prtg_domain_types = { for dvo in aws_acm_certificate.prtg_lb_cert.domain_validation_options : dvo.domain_name => {
    name   = dvo.resource_record_name
    record = dvo.resource_record_value
    type   = dvo.resource_record_type
    }
  }

  prtg_domain_name_main   = [for k, v in local.prtg_domain_types : v.name if k == "modernisation-platform.service.justice.gov.uk"]
  prtg_domain_name_sub    = [for k, v in local.prtg_domain_types : v.name if k != "modernisation-platform.service.justice.gov.uk"]
  prtg_domain_record_main = [for k, v in local.prtg_domain_types : v.record if k == "modernisation-platform.service.justice.gov.uk"]
  prtg_domain_record_sub  = [for k, v in local.prtg_domain_types : v.record if k != "modernisation-platform.service.justice.gov.uk"]
  prtg_domain_type_main   = [for k, v in local.prtg_domain_types : v.type if k == "modernisation-platform.service.justice.gov.uk"]
  prtg_domain_type_sub    = [for k, v in local.prtg_domain_types : v.type if k != "modernisation-platform.service.justice.gov.uk"]



  # This is used to prevent our bare metal server from deploying in environments other than production
  only_in_production_mapping = {
    development   = 0
    preproduction = 0
    production    = 1
  }
  only_in_production = local.only_in_production_mapping[local.environment]

}