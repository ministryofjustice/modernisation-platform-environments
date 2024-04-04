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

  non_prod_validation = {
    "modernisation-platform.service.justice.gov.uk" = {
      account   = "core-network-services"
      zone_name = "modernisation-platform.service.justice.gov.uk."
    }
    "*.${var.networking[0].business-unit}-${local.environment}.modernisation-platform.service.justice.gov.uk" = {
      account   = "core-vpc"
      zone_name = "${local.vpc_name}-${local.environment}.modernisation-platform.service.justice.gov.uk."
    }
  }

  prod_validation = {
    "${local.application_data.accounts[local.environment].acm_cert_domain_name}" = {
      account   = "core-network-services"
      zone_name = "ccms-ebs.service.justice.gov.uk"
    }
  }

  cert_opts    = local.environment == "production" ? aws_acm_certificate.external-service[0].domain_validation_options : aws_acm_certificate.external[0].domain_validation_options
  cert_arn     = local.environment == "production" ? aws_acm_certificate.external-service[0].arn : aws_acm_certificate.external[0].arn
  cert_zone_id = local.environment == "production" ? data.aws_route53_zone.application-zone.zone_id : data.aws_route53_zone.network-services.zone_id
}
