locals {
  bucket_configuration     = local.application_data.accounts[local.environment].bucket_configuration
  custom_idp_configuration = local.application_data.accounts[local.environment].custom_idp_configuration
  iam_configuration        = local.application_data.accounts[local.environment].iam_configuration
  notification_configuration = try(
    local.application_data.accounts[local.environment].notification_configuration,
    {},
  )
  team_channel_notification_configuration = try(
    local.notification_configuration.team_channel,
    {},
  )
  high_priority_alerts_notification_configuration = try(
    local.notification_configuration.high_priority_alerts,
    {},
  )
  low_priority_alerts_notification_configuration = try(
    local.notification_configuration.low_priority_alerts,
    {},
  )
  vpc_configuration = local.application_data.accounts[local.environment].vpc_configuration
}
