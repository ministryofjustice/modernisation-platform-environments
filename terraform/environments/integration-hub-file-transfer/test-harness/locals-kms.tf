locals {
  incoming_kms_key_alias    = "alias/s3/incoming"
  destination_kms_key_alias = "s3/${local.destination_bucket_name}"
}