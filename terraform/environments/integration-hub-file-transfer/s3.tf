module "s3_audit_bucket" {
  #checkov:skip=CKV_TF_1:Module registry does not support commit hashes for versions
  source  = "terraform-aws-modules/s3-bucket/aws"
  version = "5.15.4"

  allowed_kms_key_arn                   = module.kms_s3_audit.key_arn
  attach_deny_insecure_transport_policy = true
  attach_policy                         = true
  bucket                                = "${local.application_name}-${local.environment}-cloudtrail-logs"
  policy                                = data.aws_iam_policy_document.s3_audit.json

  server_side_encryption_configuration = {
    rule = {
      apply_server_side_encryption_by_default = {
        kms_master_key_id = module.kms_s3_audit.key_arn
        sse_algorithm     = "aws:kms"
      }
    }
  }

  block_public_acls       = true
  ignore_public_acls      = true
  block_public_policy     = true
  restrict_public_buckets = true

  lifecycle_rule = [
    {
      id     = "expire-cloudtrail-logs-after-13-months"
      status = "Enabled"
      filter = {}
      expiration = {
        # S3 lifecycle expiry is configured in days; 400 days retains logs for at least 13 months.
        days = 400
      }
      noncurrent_version_expiration = {
        noncurrent_days = 400
      }
    }
  ]

  versioning = {
    status     = true
    mfa_delete = false
  }

  tags = local.tags
}

module "s3_bucket" {
  #checkov:skip=CKV_TF_1:Module registry does not support commit hashes for versions
  for_each = {
    for key, value in local.s3_bucket_configuration : key => value
  }
  source  = "terraform-aws-modules/s3-bucket/aws"
  version = "5.15.4"

  allowed_kms_key_arn                   = module.kms_s3_bucket[each.key].key_arn
  attach_deny_insecure_transport_policy = true
  bucket                                = each.value.bucket

  cors_rule = each.key == "incoming" ? [
    {
      allowed_headers = ["*"]
      allowed_methods = ["GET", "PUT", "POST", "DELETE", "HEAD"]
      allowed_origins = [aws_transfer_web_app.this.access_endpoint]
      expose_headers = [
        "last-modified",
        "content-length",
        "etag",
        "x-amz-version-id",
        "content-type",
        "x-amz-request-id",
        "x-amz-id-2",
        "date",
        "x-amz-cf-id",
        "x-amz-storage-class",
        "access-control-expose-headers",
      ]
      max_age_seconds = 3000
    }
  ] : []

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

  tags = local.tags
}

resource "aws_s3_bucket_notification" "eventbridge" {
  for_each = {
    for key, value in local.s3_bucket_configuration : key => value
    if value.eventbridge
  }

  bucket      = module.s3_bucket[each.key].s3_bucket_id
  eventbridge = true
}
