module "s3_cica_dms_ingress_kms" {
  #checkov:skip=CKV_TF_1:Module registry does not support commit hashes for versions

  count = local.environment == "production" ? 1 : 0

  source  = "terraform-aws-modules/kms/aws"
  version = "3.1.0"

  aliases               = ["s3/cica-dms-ingress"]
  description           = "Used in the CICA DMS Ingress Solution"
  enable_default_policy = true
  multi_region          = true

  deletion_window_in_days = 7
}


module "dms_kms_source_cmk" {
  source  = "terraform-aws-modules/kms/aws"
  version = "3.1.0"
  aliases               = ["dms"]
  description           = "Data Migration Service KMS Key to be used as a Customer Managed Key"
  enable_default_policy = true

  deletion_window_in_days = 7
}

output "dms_kms_source_cmk_arn" {
  value = module.dms_kms_source_cmk.key_id
}