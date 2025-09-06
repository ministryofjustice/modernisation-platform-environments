locals {
  athena_query_bucket_name = "mojap-next-poc-hub-athena-query"
  producer_account_id      = local.environment_management.account_ids["analytical-platform-next-poc-producer-development"]
  producer_database        = "moj"

  users = [
    # slugified emails
    "jacobwoffenden",
    "michaelcollins5",
    "jamesstott"
  ]
}
