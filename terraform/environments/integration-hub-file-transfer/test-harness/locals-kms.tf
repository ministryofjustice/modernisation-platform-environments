locals {
  incoming_kms_key_alias               = "alias/s3/incoming"
  push_to_s3_destination_kms_key_alias = "s3/${local.push_to_s3_destination_bucket_name}"

  hosted_pickup_kms_key_alias = "alias/s3/${local.hosted_pickup_bucket_name}"
}