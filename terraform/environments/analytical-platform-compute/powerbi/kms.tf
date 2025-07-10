# KMS key for encrypting Auth0 secrets
module "auth0_secrets_kms" {
  #checkov:skip=CKV_TF_1:Module registry does not support commit hashes for versions
  #checkov:skip=CKV_TF_2:Module registry does not support tags for versions

  source  = "terraform-aws-modules/kms/aws"
  version = "4.0.0"

  description             = "KMS key for Auth0 provider secrets"
  key_usage               = "ENCRYPT_DECRYPT"
  enable_key_rotation     = true
  deletion_window_in_days = 7

  aliases = ["auth0-${local.environment}"]
  tags    = local.tags
}
