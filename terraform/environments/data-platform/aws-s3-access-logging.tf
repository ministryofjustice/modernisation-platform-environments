module "s3_access_logs_kms_key" {
  source = "github.com/terraform-aws-modules/terraform-aws-kms.git?ref=83e5418372a0716f6dae00ef04eaf42110f9f072" # v4.1.0

  aliases                 = ["s3/mojdp-${local.environment}-s3-access-logs"]
  enable_default_policy   = true
  deletion_window_in_days = 7
}

module "s3_access_logs_s3_bucket" {
  source = "github.com/terraform-aws-modules/terraform-aws-s3-bucket.git?ref=c375418373496865e2770ad8aabfaf849d4caee5" # v5.7.0

  bucket = "mojdp-${local.environment}-s3-access-logs"

  server_side_encryption_configuration = {
    rule = {
      bucket_key_enabled = true
      apply_server_side_encryption_by_default = {
        kms_master_key_id = module.s3_access_logs_kms_key.key_arn
        sse_algorithm     = "aws:kms"
      }
    }
  }
}
