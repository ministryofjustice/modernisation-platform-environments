module "kms_test_harness" {
  #checkov:skip=CKV_TF_1:Module registry does not support commit hashes for versions
  source  = "terraform-aws-modules/kms/aws"
  version = "4.2.2"

  create = local.create_test_harness

  description             = "Encryption for the test harness delivery destination"
  aliases                 = [local.destination_kms_key_alias]
  enable_default_policy   = true
  enable_key_rotation     = true
  deletion_window_in_days = 30
  key_usage               = "ENCRYPT_DECRYPT"
  multi_region            = false

  tags = local.tags
}