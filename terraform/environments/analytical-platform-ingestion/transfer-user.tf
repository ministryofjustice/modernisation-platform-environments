module "sftp_users" {
  for_each = local.environment_configuration.transfer_server_sftp_users

  source = "./modules/transfer-family/user"

  name    = each.key
  ssh_key = each.value.ssh_key

  transfer_server        = aws_transfer_server.this.id
  landing_bucket         = module.landing_bucket.s3_bucket_id
  landing_bucket_kms_key = module.s3_landing_kms.key_arn
  supplier_data_kms_key  = module.supplier_data_kms.key_arn
}

module "sftp_users_with_egress" {
  for_each = local.environment_configuration.transfer_server_sftp_users_with_egress

  source = "./modules/transfer-family/user-with-egress"

  name    = each.key
  ssh_key = each.value.ssh_key

  transfer_server        = aws_transfer_server.this.id
  landing_bucket         = module.landing_bucket.s3_bucket_id
  landing_bucket_kms_key = module.s3_landing_kms.key_arn
  egress_bucket          = each.value.egress_bucket
  egress_bucket_kms_key  = each.value.egress_bucket_kms_key
  supplier_data_kms_key  = module.supplier_data_kms.key_arn
}
