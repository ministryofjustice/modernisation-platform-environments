#### This file can be used to store locals specific to the member account ####

locals {
  artefact_bucket_name = "${local.application_name}-${local.environment}-artefacts"
  logging_bucket_name  = "${local.application_name}-${local.environment}-logging"
  rsync_bucket_name    = "${local.application_name}-${local.environment}-dbbackup"
  lb_log_prefix        = "ebsapps-lb"

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
}
