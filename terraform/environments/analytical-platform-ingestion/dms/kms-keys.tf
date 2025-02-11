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
