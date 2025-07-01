module "sftp_users" {
  for_each = local.environment_configuration.transfer_server_sftp_users

  source = "./modules/transfer-family/user"

  name        = each.key
  ssh_key     = each.value.ssh_key
  cidr_blocks = each.value.cidr_blocks

  transfer_server                = aws_transfer_server.this.id
  transfer_server_security_group = aws_security_group.transfer_server.id
  landing_bucket                 = aws_s3_bucket.CAFM.id
  landing_bucket_kms_key         = aws_kms_key.sns_kms.arn
  supplier_data_kms_key          = aws_kms_key.sns_kms.arn
}
