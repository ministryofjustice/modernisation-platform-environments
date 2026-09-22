locals {
  clean_bucket_name = "${local.application_name}-${local.environment}-clean"

  hosted_bucket_names = {
    for entry_id in keys(local.hosted_pickup_entries) :
    entry_id => "ihft-${local.environment}-hosted-pickup-${data.aws_caller_identity.current.account_id}-${entry_id}"
  }
}