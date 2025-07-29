#### This file can be used to store locals specific to the member account ####
locals {
  artefact_bucket_name       = "${local.application_name}-${local.environment}-artefacts"
  logging_bucket_name        = "${local.application_name}-${local.environment}-logging"
  rsync_bucket_name          = "${local.application_name}-${local.environment}-dbbackup"
  lb_log_prefix_ebsapp       = "ebsapps-lb"
  lb_log_prefix_wgate        = "wgate-lb"
  lb_log_prefix_wgate_public = "wgate-lb-public"

  data_subnets = [
    data.aws_subnet.data_subnets_a.id,
    data.aws_subnet.data_subnets_b.id,
    data.aws_subnet.data_subnets_c.id
  ]

  private_subnets = [
    data.aws_subnet.private_subnets_a.id,
    data.aws_subnet.private_subnets_b.id,
    data.aws_subnet.private_subnets_c.id
  ]

  public_subnets = [
    data.aws_subnet.public_subnets_a.id,
    data.aws_subnet.public_subnets_b.id,
    data.aws_subnet.public_subnets_c.id
  ]

  #  cert_opts    = local.environment == "production" ? aws_acm_certificate.external-service[0].domain_validation_options : aws_acm_certificate.external[0].domain_validation_options
  cert_arn     = aws_acm_certificate.external.arn
  cert_zone_id = local.environment == "production" ? data.aws_route53_zone.application-zone.zone_id : data.aws_route53_zone.network-services.zone_id

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

  #--Cash office. Transfer family CSR mapping. Production only
/*   transfer_family_dvo_map = local.is-production && length(aws_acm_certificate.transfer_family) > 0 ? {
    for dvo in aws_acm_certificate.transfer_family[0].domain_validation_options :
    dvo.domain_name => {
      name   = dvo.resource_record_name
      record = dvo.resource_record_value
      type   = dvo.resource_record_type
    }
  } : {} */
}
