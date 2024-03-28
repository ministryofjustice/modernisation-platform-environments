module "sftp_users" {
  for_each = local.environment_configuration.transfer_server_sftp_users

  source = "./modules/transfer-family/user"

  name        = each.key
  ssh_key     = each.value.ssh_key
  cidr_blocks = each.value.cidr_blocks

  transfer_server                = aws_transfer_server.this.id
  transfer_server_security_group = aws_security_group.transfer_server.id
  landing_bucket                 = module.landing_bucket.s3_bucket_id
  landing_bucket_kms_key         = module.s3_landing_kms.key_arn
  supplier_data_kms_key          = module.supplier_data_kms.key_arn
}
