module "s3-bucket" { #tfsec:ignore:aws-s3-enable-versioning
  source = "github.com/ministryofjustice/modernisation-platform-terraform-s3-bucket?ref=v6.3.0"

  bucket_prefix      = "data-platform-landing"
  versioning_enabled = false
  bucket_policy      = [data.aws_iam_policy_document.bucket_policy.json]

  tags = local.tags
}


data "aws_iam_policy_document" "bucket_policy" {
  statement {
    sid = "AllowPutFromCiUser"
    effect = "Allow"

    principals {
      type        = "AWS"
      identifiers = ["arn:aws:iam::013433889002:user/cicd-member-user"]
    }

    actions = ["s3:PutObject", "s3:ListBucket"]

    resources = [module.s3-bucket.bucket.arn, "${module.s3-bucket.bucket.arn}/*"]
  }

  statement {
    sid = "DenyNonFullControlObjects"
    effect = "Deny"
    actions = ["s3:PutObject"]
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
    sid = "DenyNonSecureTransport"
    effect = "Deny"
    actions = ["s3:PutObject"]
    resources = ["${module.s3-bucket.bucket.arn}/*"]
    condition {
        test     = "Bool"
        variable = "aws:SecureTransport"

        values   = ["false"]
      }
  }
}
