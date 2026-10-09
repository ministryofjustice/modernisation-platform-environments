locals {
  incoming_bucket_name    = "${local.application_name}-${local.environment}-incoming"
  destination_bucket_name = "${local.application_name}-${local.environment}-${local.component_name}"

  incoming_prefix    = "${local.component_name}/${local.destination_prefix}"
  destination_prefix = "push-to-s3/"
}