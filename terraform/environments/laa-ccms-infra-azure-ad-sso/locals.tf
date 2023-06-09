#### This file can be used to store locals specific to the member account ####
locals {
  logging_bucket_name = "${local.application_name}-${local.environment}-logging"
  lb_log_prefix       = "ebs-vision-db-lb"
  dns_name            = "modernisation-platform.service.justice.gov.uk"
  vision_dns          = "azure-ad-ebs-db"
  vision_host         = "${local.vision_dns}.${var.networking[0].business-unit}-${local.environment}.modernisation-platform.service.justice.gov.uk"
}
