module "kms" {
  #checkov:skip=CKV_TF_1:Module registry does not support commit hashes for versions
  source  = "terraform-aws-modules/kms/aws"
  version = "3.1.1"

  deletion_window_in_days = 7
  description             = "KMS key for ${local.project_name}"
  enable_key_rotation     = true
  is_enabled              = true
  key_usage               = "ENCRYPT_DECRYPT"

  aliases = [local.project_name]

  tags = local.tags
}
#todo add to all secrets
