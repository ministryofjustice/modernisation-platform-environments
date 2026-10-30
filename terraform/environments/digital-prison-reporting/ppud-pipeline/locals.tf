locals {
  days_back                    = local.is-test ? 1 : local.application_data.accounts[local.environment].days_back
  cron_schedule                = local.is-test ? "rate(1 day)" : local.application_data.accounts[local.environment].cron_schedule
  short_name_environment       = local.is-test ? "test" : local.application_data.accounts[local.environment].short_name_environment
  analytical_platform_share    = can(local.application_data.accounts[local.environment].analytical_platform_share) ? { for share in local.application_data.accounts[local.environment].analytical_platform_share : share.target_account_name => share } : {}
  ppud_replication_environment = local.is-test ? "test" : local.application_data.accounts[local.environment].ppud_replication_environment
}
