#### This file can be used to store locals specific to the member account ####
locals {
  artefact_bucket_name = "ccms-ebs-${local.component_name}-artefacts"
  logging_bucket_name  = "ccms-ebs-${local.component_name}-logging"
  rsync_bucket_name    = "ccms-ebs-${local.component_name}-dbbackup"
  lb_log_prefix_ebsapp = "${local.component_name}-ebsapps-lb"

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

  cert_opts    = aws_acm_certificate.external.domain_validation_options
  cert_arn     = aws_acm_certificate.external.arn
  cert_zone_id = data.aws_route53_zone.external.zone_id
}
