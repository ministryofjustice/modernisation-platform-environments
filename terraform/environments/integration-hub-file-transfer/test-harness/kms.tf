module "destination-encryption" {
  #checkov:skip=CKV_TF_1:Module registry does not support commit hashes for versions
  source  = "terraform-aws-modules/kms/aws"
  version = "4.2.2"

  create = local.create_test_harness

  description             = "Encryption for the test harness delivery destination"
  aliases                 = ["s3/${local.application_name}-${local.component_name}-${local.environment}-delivery"]
  enable_default_policy   = true
  enable_key_rotation     = true
  deletion_window_in_days = 30
  key_usage               = "ENCRYPT_DECRYPT"
  multi_region            = false

  tags = local.tags
}