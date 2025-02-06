
module "dms_kms_source_cmk" {
  #checkov:skip=CKV_TF_1:Module registry does not support commit hashes for versions

  source  = "terraform-aws-modules/kms/aws"
  version = "3.1.0"

  aliases               = ["dms"]
  description           = "Data Migration Service KMS Key to be used as a Customer Managed Key"
  enable_default_policy = true

  deletion_window_in_days = 7
}
