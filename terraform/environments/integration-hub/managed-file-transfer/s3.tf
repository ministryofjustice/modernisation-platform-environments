module "s3_bucket" {
  for_each = {
    for key, value in local.bucket_configuration : key => value
  }
  source  = "terraform-aws-modules/s3-bucket/aws"
  version = "5.14.1"

  allowed_kms_key_arn                   = module.kms_s3_bucket[each.key].key_arn
  attach_policy                         = contains(["clean", "processing", "quarantine", "unscanned"], each.key)
  attach_deny_insecure_transport_policy = true
  bucket_prefix                         = each.value.bucket_prefix
  policy = lookup(
    {
      clean      = data.aws_iam_policy_document.clean.json
      unscanned  = data.aws_iam_policy_document.unscanned.json
      processing = data.aws_iam_policy_document.processing.json
      quarantine = data.aws_iam_policy_document.quarantine.json
    },
    each.key,
    null
  )
  cors_rule = each.key == "unscanned" ? [
    {
      allowed_headers = ["*"]
      allowed_methods = ["GET", "PUT", "POST", "DELETE", "HEAD"]
      allowed_origins = [local.web_app_origin]
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

  lifecycle_rule = each.value.lifecycle_rule
  versioning = {
    status     = true
    mfa_delete = false
  }
}

resource "aws_s3_bucket_notification" "unscanned" {
  bucket = module.s3_bucket["unscanned"].s3_bucket_id

  queue {
    id        = "unscanned"
    queue_arn = module.sqs_unscanned_s3_notifications.queue_arn
    events    = ["s3:ObjectCreated:*"]
  }

  depends_on = [module.sqs_unscanned_s3_notifications]
}
