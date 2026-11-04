module "secrets_private_key" {
  #checkov:skip=CKV_TF_1:Module registry does not support commit hashes for versions
  source  = "terraform-aws-modules/secrets-manager/aws"
  version = "2.2.0"

  for_each = local.push_to_sftp_entries

  name                    = "${local.application_name}/push-to-sftp/${each.value.name_suffix}/private-key"
  description             = "Operator-populated SSH private key JSON for ${each.value.name_suffix}"
  kms_key_id              = module.kms_credentials.key_arn
  recovery_window_in_days = 30

  create_secret_version  = false
  create_random_password = false

  tags = local.tags
}

module "secrets_public_key" {
  #checkov:skip=CKV_TF_1:Module registry does not support commit hashes for versions
  source  = "terraform-aws-modules/secrets-manager/aws"
  version = "2.2.0"

  for_each = local.push_to_sftp_entries

  name                    = "${local.application_name}/push-to-sftp/${each.value.name_suffix}/public-key"
  description             = "Operator-populated OpenSSH client public key for ${each.value.name_suffix}"
  kms_key_id              = module.kms_credentials.key_arn
  recovery_window_in_days = 30

  create_secret_version  = false
  create_random_password = false

  tags = local.tags
}