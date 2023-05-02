#### This file can be used to store locals specific to the member account ####
locals {
  logging_bucket_name = "${local.application_name}-${local.environment}-logging"
  lb_log_prefix       = "ebs-vision-db-lb"
  dns_name            = "modernisation-platform.service.justice.gov.uk"
}
