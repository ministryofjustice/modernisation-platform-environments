locals {
  bucket_configuration = local.application_data.accounts[local.environment].bucket_configuration
  iam_configuration    = local.application_data.accounts[local.environment].iam_configuration
  notification_configuration = merge(
    {
      slack_channel_id                 = null
      slack_team_id                    = null
      max_presigned_url_expiry_seconds = 3600
      presigned_url_expiry_seconds     = 1800
    },
    try(local.application_data.accounts[local.environment].notification_configuration, {})
  )
  vpc_configuration = local.application_data.accounts[local.environment].vpc_configuration
}
