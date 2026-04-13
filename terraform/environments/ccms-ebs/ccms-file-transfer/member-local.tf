locals {
  sftp_client1_folder_name = ["inbound", "archive", "error"]
  sftp_client1_bucket_name = "${local.application_name}-${local.environment}-barclaycard-inbound-mp"
  logging_bucket_name      = "${local.application_name}-${local.environment}-logging"
}