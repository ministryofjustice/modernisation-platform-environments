module "transfer_family" {
  count                            = local.is-development ? 1 : 0
  source                           = "./modules/transfer-family"
  aws_account_id                   = data.aws_caller_identity.current.account_id
  app_name                         = local.application_name
  bucket_name                      = aws_s3_bucket.buckets["laa-ccms-inbound-${local.environment}-mp"].bucket
  aws_identity_centre_store_arn    = local.application_data.accounts[local.environment].cash_office_idp_arn
  aws_identity_centre_sso_group_id = local.application_data.accounts[local.environment].cash_office_sso_group_id
}

