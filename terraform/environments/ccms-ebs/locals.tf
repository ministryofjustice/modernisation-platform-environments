#### This file can be used to store locals specific to the member account ####

locals {
  artefact_bucket_name = "${local.application_name}-${local.environment}-artefacts"
  logging_bucket_name  = "${local.application_name}-${local.environment}-logging"
  rsync_bucket_name    = "${local.application_name}-${local.environment}-dbbackup"
  lb_log_prefix        = "ebsapps-lb"
}
