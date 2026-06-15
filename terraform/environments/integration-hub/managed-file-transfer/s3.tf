data "aws_iam_policy_document" "unscanned" {
  statement {
    sid    = "DenyGuardDutyTagWrites"
    effect = "Deny"

    principals {
      type        = "AWS"
      identifiers = ["*"]
    }

    actions = [
      "s3:PutObject",
      "s3:PutObjectTagging",
      "s3:PutObjectVersionTagging",
    ]

    # The S3 bucket module replaces the bucket placeholders with the created bucket ARN.
    resources = [
      "_S3_BUCKET_ARN_/*",
    ]

    condition {
      test     = "ForAnyValue:StringEquals"
      variable = "s3:RequestObjectTagKeys"
      values   = ["GuardDutyMalwareScanStatus"]
    }
  }
}

data "aws_iam_policy_document" "processing" {
  statement {
    sid    = "DenyGuardDutyTagWritesFromNonGuardDutyPrincipals"
    effect = "Deny"

    principals {
      type        = "AWS"
      identifiers = ["*"]
    }

    actions = [
      "s3:PutObject",
      "s3:PutObjectTagging",
      "s3:PutObjectVersionTagging",
    ]

    resources = [
      "_S3_BUCKET_ARN_/*",
    ]

    condition {
      test     = "ArnNotEquals"
      variable = "aws:PrincipalArn"
      values = [
        "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/${local.iam_configuration.guardduty_role_name}",
      ]
    }

    condition {
      test     = "ForAnyValue:StringEquals"
      variable = "s3:RequestObjectTagKeys"
      values   = ["GuardDutyMalwareScanStatus"]
    }
  }

  statement {
    sid    = "DenyGuardDutyTagMutationFromNonGuardDutyPrincipals"
    effect = "Deny"

    principals {
      type        = "AWS"
      identifiers = ["*"]
    }

    actions = [
      "s3:PutObjectTagging",
      "s3:PutObjectVersionTagging",
      "s3:DeleteObjectTagging",
      "s3:DeleteObjectVersionTagging",
    ]

    resources = [
      "_S3_BUCKET_ARN_/*",
    ]

    condition {
      test     = "ArnNotEquals"
      variable = "aws:PrincipalArn"
      values = [
        "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/${local.iam_configuration.guardduty_role_name}",
      ]
    }

    condition {
      test     = "Null"
      variable = "s3:ExistingObjectTag/GuardDutyMalwareScanStatus"
      values   = ["false"]
    }
  }
}

module "s3_bucket" {
  for_each = {
    for key, value in local.bucket_configuration : key => value
  }
  source  = "terraform-aws-modules/s3-bucket/aws"
  version = "5.14.0"

  allowed_kms_key_arn                   = module.kms_s3_bucket[each.key].key_arn
  attach_policy                         = contains(["processing", "unscanned"], each.key)
  attach_deny_insecure_transport_policy = true
  bucket_prefix                         = each.value.bucket_prefix
  policy = lookup(
    {
      unscanned  = data.aws_iam_policy_document.unscanned.json
      processing = data.aws_iam_policy_document.processing.json
    },
    each.key,
    null
  )
  cors_rule = each.key == "unscanned" ? [
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
