locals {
  days_back     = local.application_data.accounts[local.environment].days_back
  cron_schedule = local.application_data.accounts[local.environment].cron_schedule
}
