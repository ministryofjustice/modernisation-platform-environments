module "transfer_family" {
  source           = "./modules/transfer-family"
  aws_account_id   = data.aws_caller_identity.current.account_id
  app_name         = local.application_name
  bucket_name      = aws_s3_bucket.buckets["laa-ccms-inbound-${local.environment}-mp"].bucket
  entra_group_name = local.application_data.accounts[local.environment].cash_office_entra_group_name
}
