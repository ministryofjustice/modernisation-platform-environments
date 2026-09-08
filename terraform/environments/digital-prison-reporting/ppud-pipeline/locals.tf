locals {
  days_back              = local.is-test ? 1 : local.application_data.accounts[local.environment].days_back
  cron_schedule          = local.is-test ? "rate(1 day)" : local.application_data.accounts[local.environment].cron_schedule
  short_name_environment = local.is-test ? "test" : local.application_data.accounts[local.environment].short_name_environment
  source_bucket_role_arn = local.is-test ? "arn" : "arn:aws:iam::${local.environment_management.account_ids["analytical-platform-data-engineering-production"]}:role/${local.application_data.accounts[local.environment].source_bucket_role_name}"

}
