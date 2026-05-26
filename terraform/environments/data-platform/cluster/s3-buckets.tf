module "opencost_spot_data_bucket" {
  source = "git::https://github.com/terraform-aws-modules/terraform-aws-s3-bucket.git?ref=0662a7bdfceac73daed7c08df2b421707de341df" # v5.9.0

  bucket = local.opencost_spot_data_bucket_name

  force_destroy = false

  object_lock_enabled = false

  server_side_encryption_configuration = {
    rule = {
      bucket_key_enabled = true
      apply_server_side_encryption_by_default = {
        kms_master_key_id = module.opencost.key_arn
        sse_algorithm     = "aws:kms"
      }
    }
  }

  versioning = {
    status = "Enabled"
  }

  tags = local.tags
}
