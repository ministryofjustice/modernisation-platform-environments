locals {
  clean_bucket_name = "${local.application_name}-${local.environment}-clean"

  hosted_bucket_names = {
    for entry_id, entry in local.hosted_pickup_entries :
    entry_id => "integration-hub-${local.environment}-${entry.identity}-pickup"
  }
}