#### This file can be used to store locals specific to the member account ####
locals {
  # create name, record,type for monitoring lb aka tipstaff_lb
  domain_types = { for dvo in aws_acm_certificate.external[0].domain_validation_options : dvo.domain_name => {
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

  # domain_types_prod = local.is-production ? { for dvo in aws_acm_certificate.external_prod[0].domain_validation_options : dvo.domain_name => {
  #   name   = dvo.resource_record_name
  #   record = dvo.resource_record_value
  #   type   = dvo.resource_record_type
  #   }
  # } : {}

  # domain_name_main_prod   = local.is-production ? [for k, v in local.domain_types_prod : v.name if k == "tipstaff.service.justice.gov.uk"] : []
  # domain_name_sub_prod    = local.is-production ? [for k, v in local.domain_types_prod : v.name if k != "tipstaff.service.justice.gov.uk"] : []
  # domain_record_main_prod = local.is-production ? [for k, v in local.domain_types_prod : v.record if k == "tipstaff.service.justice.gov.uk"] : []
  # domain_record_sub_prod  = local.is-production ? [for k, v in local.domain_types_prod : v.record if k != "tipstaff.service.justice.gov.uk"] : []
  # domain_type_main_prod   = local.is-production ? [for k, v in local.domain_types_prod : v.type if k == "tipstaff.service.justice.gov.uk"] : []
  # domain_type_sub_prod    = local.is-production ? [for k, v in local.domain_types_prod : v.type if k != "tipstaff.service.justice.gov.uk"] : []


  # cert_opts    = local.is-production ? aws_acm_certificate.external_prod[0].domain_validation_options : aws_acm_certificate.external[0].domain_validation_options
  # cert_arn     = local.is-production ? aws_acm_certificate.external_prod[0].arn : aws_acm_certificate.external[0].arn
  # cert_zone_id = local.is-production ? data.aws_route53_zone.application-zone.zone_id : data.aws_route53_zone.network-services.zone_id

}
