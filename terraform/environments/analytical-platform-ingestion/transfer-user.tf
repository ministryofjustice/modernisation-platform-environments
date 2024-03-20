locals {
  sftp_users = {
    "jacobwoffenden" = {
      ssh_key     = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIN+3qaLVtn6Pd+DasWHhIOBoXEEhF9GZAG+DYfJBeySS Ministry of Justice"
      cidr_blocks = ["90.246.52.170/32", "82.132.238.3/32"]
    },
    "garyhenderson" = {
      ssh_key     = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAID2lrI7AhZ9Sy/JAVDfPPEkCZawuuVJ7MHg6NNAwYImb"
      cidr_blocks = ["154.47.111.68/32"]
    }
  }
}

module "sftp_users" {
  for_each = local.sftp_users

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
