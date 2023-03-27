module "s3-bucket" { #tfsec:ignore:aws-s3-enable-versioning
  source = "github.com/ministryofjustice/modernisation-platform-terraform-s3-bucket?ref=v6.3.0"

  bucket_prefix = "data-platform-landing"
  # Refer to the below section "Replication" before enabling replication
  replication_enabled = false

  providers = {
    # Here we use the default provider Region for replication. Destination buckets can be within the same Region as the
    # source bucket. On the other hand, if you need to enable cross-region replication, please contact the Modernisation
    # Platform team to add a new provider for the additional Region.
    aws.bucket-replication = aws
  }

  lifecycle_rule = [
    {
      id      = "main"
      enabled = "Enabled"
      prefix  = ""

      tags = {
        rule      = "log"
        autoclean = "true"
      }

      transition = [
        {
          days          = 90
          storage_class = "STANDARD_IA"
          }, {
          days          = 365
          storage_class = "GLACIER"
        }
      ]

      expiration = {
        days = 730
      }

      noncurrent_version_transition = [
        {
          days          = 90
          storage_class = "STANDARD_IA"
          }, {
          days          = 365
          storage_class = "GLACIER"
        }
      ]

      noncurrent_version_expiration = {
        days = 730
      }
    }
  ]

  tags = local.tags
}


data "aws_iam_policy_document" "bucket_policy" {
  statement {
    sid    = "AllowPutFromCiUser"
    effect = "Allow"

    principals {
      type        = "AWS"
      identifiers = ["arn:aws:iam::${data.aws_caller_identity.current.account_id}:user/cicd-member-user"]
    }

    actions = ["s3:PutObject", "s3:ListBucket"]

    resources = [module.s3-bucket.bucket.arn, "${module.s3-bucket.bucket.arn}/*"]
  }

  statement {
    sid       = "DenyNonFullControlObjects"
    effect    = "Deny"
    actions   = ["s3:PutObject"]
    resources = ["${module.s3-bucket.bucket.arn}/*"]

    condition {
      test     = "StringNotEquals"
      variable = "s3:x-amz-acl"

      values = [
        "bucket-owner-full-control"
      ]
    }
  }

  statement {
    sid       = "DenyNonSecureTransport"
    effect    = "Deny"
    actions   = ["s3:*"]
    resources = [module.s3-bucket.bucket.arn, "${module.s3-bucket.bucket.arn}/*"]
    condition {
      test     = "Bool"
      variable = "aws:SecureTransport"

      values = ["false"]
    }
  }
}
