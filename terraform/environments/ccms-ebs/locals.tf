#### This file can be used to store locals specific to the member account ####
locals {
  artefact_bucket_name  = "${local.application_name}-${local.environment}-artefacts"
  logging_bucket_name   = "${local.application_name}-${local.environment}-logging"
  rsync_bucket_name     = "${local.application_name}-${local.environment}-dbbackup"
  lb_log_prefix_ebsapp  = "ebsapps-lb"
  lb_log_prefix_wgate   = "wgate-lb"


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

  cert_opts    = local.environment == "production" ? aws_acm_certificate.external-service[0].domain_validation_options : aws_acm_certificate.external[0].domain_validation_options
  cert_arn     = local.environment == "production" ? aws_acm_certificate.external-service[0].arn : aws_acm_certificate.external[0].arn
  cert_zone_id = local.environment == "production" ? data.aws_route53_zone.application-zone.zone_id : data.aws_route53_zone.network-services.zone_id
}
