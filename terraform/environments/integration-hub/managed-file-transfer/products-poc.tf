module "proof_of_concept_notification" {
  source = "./modules/send-presigned-url"

  account_id                  = data.aws_caller_identity.current.account_id
  application_name            = local.application_name
  download_bucket_arn         = module.s3_bucket["clean"].s3_bucket_arn
  download_bucket_kms_key_arn = module.kms_s3_bucket["clean"].key_arn
  download_bucket_name        = module.s3_bucket["clean"].s3_bucket_id
  name_suffix                 = ""
  max_presigned_url_expiry_seconds = try(
    local.notification_configuration.max_presigned_url_expiry_seconds,
    3600,
  )
  presigned_url_expiry_seconds = try(
    local.notification_configuration.presigned_url_expiry_seconds,
    1800,
  )
  slack_channel_id = try(
    local.notification_configuration.slack_channel_id,
    null,
  )
  slack_team_id = try(
    local.notification_configuration.slack_team_id,
    null,
  )
  tags = local.tags
}
