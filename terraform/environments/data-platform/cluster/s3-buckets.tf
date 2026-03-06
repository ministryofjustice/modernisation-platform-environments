module "velero_s3_bucket" {
  source = "git::https://github.com/terraform-aws-modules/terraform-aws-s3-bucket.git?ref=b040965a526e22a78784840c2f2ae384f2a8e4ef" # v5.10.0

  bucket = "mojdp-${local.environment}-${local.component_name}-velero"

  force_destroy = false

  server_side_encryption_configuration = {
    rule = {
      bucket_key_enabled = true
      apply_server_side_encryption_by_default = {
        kms_master_key_id = module.velero_kms_key.key_arn
        sse_algorithm     = "aws:kms"
      }
    }
  }

  versioning = {
    status = "Enabled"
  }
}
