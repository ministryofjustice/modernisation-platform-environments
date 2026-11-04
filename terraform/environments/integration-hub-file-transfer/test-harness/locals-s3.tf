locals {
  incoming_bucket_name = "${local.application_name}-${local.environment}-incoming"
  clean_bucket_name    = "${local.application_name}-${local.environment}-clean"

  push_to_s3_incoming_prefix         = "${local.component_name}/${local.push_to_s3_destination_prefix}"
  push_to_s3_destination_prefix      = "push-to-s3/"
  push_to_s3_destination_bucket_name = "${local.application_name}-${local.environment}-${local.component_name}"

  # The hosted bucket is created by the push-to-s3-with-hosted-pickup component from the dispatch entry.
  hosted_pickup_incoming_prefix    = "${local.component_name}/hosted-pickup/"
  hosted_pickup_destination_prefix = "pickup/"
  hosted_pickup_bucket_name        = "integration-hub-${local.environment}-${local.component_name}-pickup"

  # The presigned pickup bucket is shared and owned by the pull-from-presigned-url component.
  presigned_incoming_prefix    = "${local.component_name}/pull-from-presigned-url/"
  presigned_recipient_id       = "test-harness-presigned"
  presigned_pickup_bucket_name = "${local.application_name}-pickup-${local.environment}-${data.aws_caller_identity.current.account_id}"

  incoming_prefixes = [
    local.push_to_s3_incoming_prefix,
    local.hosted_pickup_incoming_prefix,
    local.presigned_incoming_prefix,
    local.sftp_incoming_prefix,
  ]
}