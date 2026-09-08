locals {
  days_back     = local.is-test ? 1 : local.application_data.accounts[local.environment].days_back
  cron_schedule = local.is-test ? "rate(1 day)" : local.application_data.accounts[local.environment].cron_schedule
}
