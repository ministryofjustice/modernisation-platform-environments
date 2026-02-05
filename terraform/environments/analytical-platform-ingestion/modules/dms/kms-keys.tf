module "bucket_kms" {
  #checkov:skip=CKV_TF_1:Module registry does not support commit hashes for versions

  source  = "terraform-aws-modules/kms/aws"
  version = "3.1.1"

  aliases               = ["dms/${var.db}/bucket-kms"]
  description           = "Used to encrypt internal buckets for ${var.db} DMS module"
  enable_default_policy = true

  deletion_window_in_days = 7

  # Grants
  grants = {
    dms_task = {
      grantee_principal = aws_iam_role.dms.arn
      operations        = ["Encrypt", "Decrypt", "GenerateDataKey"]
    }
    metadata_generator = {
      grantee_principal = module.metadata_generator.lambda_role_arn
      operations        = ["Encrypt", "Decrypt", "GenerateDataKey"]
    }
    validation = {
      grantee_principal = module.validation_lambda_function.lambda_role_arn
      operations        = ["Encrypt", "Decrypt", "GenerateDataKey"]
    }
  }
}
