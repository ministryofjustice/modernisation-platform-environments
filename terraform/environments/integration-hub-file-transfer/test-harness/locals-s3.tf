locals {
  incoming_bucket_name      = "${local.application_name}-${local.environment}-incoming"
  clean_bucket_name         = "${local.application_name}-${local.environment}-clean"
  investigation_bucket_name = "${local.application_name}-${local.environment}-investigation"
  quarantine_bucket_name    = "${local.application_name}-${local.environment}-quarantine"
  destination_bucket_name   = "${local.application_name}-${local.environment}-${local.component_name}"

  incoming_prefix    = "${local.component_name}/${local.destination_prefix}"
  destination_prefix = "push-to-s3/"

  routing_test_prefixes = [
    "${local.component_name}/investigation/",
    "${local.component_name}/quarantine/",
  ]
  fixture_upload_prefixes = concat([local.incoming_prefix], local.routing_test_prefixes)
}