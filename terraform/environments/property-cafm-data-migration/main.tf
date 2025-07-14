module "server" {
  source = "./modules/transfer_family/server"
  name   = "CAFM SFTP Server"
}

# ------------------------
# Transfer User
# ------------------------
module "sftp_user" {
  source     = "./modules/transfer_family/users"
  for_each   = local.sftp_users

  user_name  = each.key
  server_id  = module.server.id
  s3_bucket  = each.value.s3_bucket
}

data "aws_ssm_parameter" "ssh_keys" {
  for_each = local.sftp_users
  name     = each.value.ssm_key_name
}

# ------------------------
# SSH Key for SFTP Login
# ------------------------
module "sftp_ssh_key" {
  source        = "./modules/transfer_family/ssh_key"
  for_each      = local.sftp_users

  server_id     = module.server.id
  user_name     = each.key
  ssh_key_body  = data.aws_ssm_parameter.ssh_keys[each.key].value

  depends_on = [module.sftp_user]
}
