module "s3_cica_dms_ingress_kms" {
  #checkov:skip=CKV_TF_1:Module registry does not support commit hashes for versions

  count = 1 # Needed (as originally conditional) to avoid destroy-create

  source  = "terraform-aws-modules/kms/aws"
  version = "3.1.0"

  aliases               = ["s3/cica-dms-ingress"]
  description           = "Used in the CICA DMS Ingress Solution"
  enable_default_policy = true
  multi_region          = true

  deletion_window_in_days = 7
}

module "cica_dms_credentials_kms" {
  #checkov:skip=CKV_TF_1:Module registry does not support commit hashes for versions

  source  = "terraform-aws-modules/kms/aws"
  version = "3.1.0"

  description           = "Used in the CICA DMS Solution to encode secrets"
  enable_default_policy = true

  deletion_window_in_days = 7

  tags = local.tags
}
