module "s3_bucket" {
  for_each = {
    for key, value in local.bucket_configuration : key => value
  }
  source  = "terraform-aws-modules/s3-bucket/aws"
  version = "5.13.0"

  allowed_kms_key_arn = module.kms_s3_bucket[each.key].key_arn
  bucket_prefix       = each.value.bucket_prefix
  server_side_encryption_configuration = {
    rule = {
      apply_server_side_encryption_by_default = {
        kms_master_key_id = module.kms_s3_bucket[each.key].key_arn
        sse_algorithm     = "aws:kms"
      }
    }
  }

  block_public_acls       = true
  ignore_public_acls      = true
  block_public_policy     = true
  restrict_public_buckets = true

  lifecycle_rule = each.value.lifecycle_rule
  versioning = {
    status     = true
    mfa_delete = false
  }
}