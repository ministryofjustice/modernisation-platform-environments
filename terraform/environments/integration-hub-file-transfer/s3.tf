module "s3_bucket" {
  for_each = {
    for key, value in local.s3_bucket_configuration : key => value
  }
  source  = "terraform-aws-modules/s3-bucket/aws"
  version = "5.14.1"

  allowed_kms_key_arn                   = module.kms_s3_bucket[each.key].key_arn
  attach_deny_insecure_transport_policy = true
  bucket                                = each.value.bucket

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

  lifecycle_rule = each.value.lifecycle_rules

  versioning = {
    status     = true
    mfa_delete = false
  }
}

resource "aws_s3_bucket_notification" "eventbridge" {
  for_each = {
    for key, value in local.s3_bucket_configuration : key => value
    if value.eventbridge
  }

  bucket      = module.s3_bucket[each.key].s3_bucket_id
  eventbridge = true
}
