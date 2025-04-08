module "s3_cica_dms_ingress_kms" {
  #checkov:skip=CKV_TF_1:Module registry does not support commit hashes for versions

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

  aliases               = ["dms/cica-source-credentials"]
  description           = "Used in the CICA DMS Solution to encode secrets"
  enable_default_policy = true

  deletion_window_in_days = 7

  # Grants
  grants = {
    dms_source = {
      grantee_principal = module.cica_dms_tariff_dms_implementation.dms_source_role_arn
      operations        = ["Encrypt", "Decrypt", "GenerateDataKey"]
    }
  }

  tags = local.tags
}
