module "proof_of_concept_notification" {
  source = "./modules/send-presigned-url"

  account_id                         = data.aws_caller_identity.current.account_id
  application_name                   = local.application_name
  aws_region                         = data.aws_region.current.region
  client_destination_delivery_config = local.client_destination_delivery
  client_destination_delivery_secret_names = distinct(compact([
    for config in values(local.client_destination_delivery) : try(config.request_auth_secret_name, null)
  ]))
  download_bucket_arn         = module.s3_bucket["clean"].s3_bucket_arn
  download_bucket_kms_key_arn = module.kms_s3_bucket["clean"].key_arn
  download_bucket_name        = module.s3_bucket["clean"].s3_bucket_id
  name_suffix                 = ""
  max_presigned_url_expiry_seconds = try(
    local.notification_configuration.team_channel.max_presigned_url_expiry_seconds,
    3600,
  )
  presigned_url_expiry_seconds = try(
    local.notification_configuration.team_channel.presigned_url_expiry_seconds,
    1800,
  )
  slack_channel_id = try(
    local.notification_configuration.team_channel.slack_channel_id,
    null,
  )
  slack_team_id = try(
    local.notification_configuration.team_channel.slack_team_id,
    null,
  )
  tags = local.tags
}
