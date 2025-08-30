locals {
  athena_query_bucket_name = "mojap-next-poc-athena-query"
  datastore_bucket_name    = "mojap-next-poc-data"
  hub_account_id           = local.environment_management.account_ids["analytical-platform-next-poc-hub-development"]
}
