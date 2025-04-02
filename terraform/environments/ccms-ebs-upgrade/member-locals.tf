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

  data_subnets_cidr_blocks = [
    data.aws_subnet.data_subnets_a.cidr_block,
    data.aws_subnet.data_subnets_b.cidr_block,
    data.aws_subnet.data_subnets_c.cidr_block
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

  cert_opts    = aws_acm_certificate.external.domain_validation_options
  cert_arn     = aws_acm_certificate.external.arn
  cert_zone_id = data.aws_route53_zone.external.zone_id
}
