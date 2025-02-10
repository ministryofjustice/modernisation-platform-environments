module "s3_cica_dms_egress_kms" {
  #checkov:skip=CKV_TF_1:Module registry does not support commit hashes for versions

  source  = "terraform-aws-modules/kms/aws"
  version = "3.1.0"

  aliases               = ["s3/cica-dms-egress"]
  description           = "Used in the CICA DMS Egress Solution"
  enable_default_policy = true
  key_statements = [
    {
      sid = "AllowAnalyticalPlatformDataProduction"
      actions = [
        "kms:Encrypt",
        "kms:GenerateDataKey"
      ]
      resources = ["*"]
      effect    = "Allow"
      principals = [
        {
          type        = "AWS"
          identifiers = ["arn:aws:iam::593291632749:role/mojap-data-production-cica-dms-egress-production"]
        }
      ]
    }
  ]
  deletion_window_in_days = 7

  count = local.environment == "production" ? 1 : 0
}
