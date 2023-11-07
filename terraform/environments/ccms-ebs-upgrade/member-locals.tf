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

  cert_zone_id = data.aws_route53_zone.network-services.zone_id
}
