module "proof_of_concept_notification" {
  source = "./modules/send-presigned-url"

  account_id                      = data.aws_caller_identity.current.account_id
  application_name                = local.application_name
  download_bucket_arn             = module.s3_bucket["clean"].s3_bucket_arn
  download_bucket_kms_key_arn     = module.kms_s3_bucket["clean"].key_arn
  download_bucket_name            = module.s3_bucket["clean"].s3_bucket_id
  idempotency_table_arn           = module.dynamodb_idempotency.dynamodb_table_arn
  idempotency_table_id            = module.dynamodb_idempotency.dynamodb_table_id
  lambda_source_path              = "${path.root}/lambda/clean-file-presigned-url-notifier"
  name_suffix                     = ""
  max_presigned_url_expiry_seconds = local.notification_configuration.max_presigned_url_expiry_seconds
  presigned_url_expiry_seconds    = local.notification_configuration.presigned_url_expiry_seconds
  slack_channel_id                = local.notification_configuration.slack_channel_id
  slack_team_id                   = local.notification_configuration.slack_team_id
  tags                            = local.tags
}
