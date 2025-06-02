# S3 buckets for MAATDB

# These are build from the local bucket_names and whether the variable build_s3 is true.

module "s3_bucket" {
  count  = local.build_s3 ? length(local.bucket_names) : 0
  source = "github.com/ministryofjustice/modernisation-platform-terraform-s3-bucket?ref=474f27a3f9bf542a8826c76fb049cc84b5cf136f"

  bucket_prefix      = lower(local.bucket_names[count.index])
  versioning_enabled = false
  force_destroy      = false
  replication_enabled = false
  replication_region = local.region

  providers = {
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
        },
        {
          days          = 180
          storage_class = "GLACIER"
        }
      ]

      noncurrent_version_expiration = {
        days = 5
      }
    }
  ]

  tags = merge(local.tags, {
    Name = lower(local.bucket_names[count.index])
  })
}

# FTP IAM User

resource "aws_iam_user" "ftp_user" {
  #checkov:skip=CKV_AWS_273:"IAM user required for backwards compatibility with existing solution"
  count = local.build_s3 ? 1 : 0
  name  = "${local.application_name}-ftp-user"
}

# IAM Policy for FTP User (access to all buckets)

data "aws_iam_policy_document" "ftp_user_policy" {
  #checkov:skip=CKV_AWS_40:"IAM user required for backwards compatibility with existing solution"
  statement {
    effect = "Allow"
    actions = [
      "s3:DeleteObject",
      "s3:DeleteObjectVersion",
      "s3:GetObject",
      "s3:GetObjectVersion",
      "s3:GetBucketPolicy",
      "s3:ListBucket",
      "s3:PutObject"
    ]

    resources = flatten([
      for bucket in module.s3_bucket : [
        bucket.bucket.arn,
        "${bucket.bucket.arn}/*"
      ]
    ])
  }
}

resource "aws_iam_user_policy" "ftp_user_policy" {
  count  = local.build_s3 ? 1 : 0
  name   = "${local.application_name}-FTPUserPolicy"
  user   = aws_iam_user.ftp_user[0].name
  policy = data.aws_iam_policy_document.ftp_user_policy.json
}

# Bucket policies (one per bucket)

data "aws_iam_policy_document" "bucket_policy" {
  count = local.build_s3 ? length(local.bucket_names) : 0

  statement {
    sid    = "AllowFTPUserAccess"
    effect = "Allow"

    principals {
      type        = "AWS"
      identifiers = [aws_iam_user.ftp_user[0].arn]
    }

    actions = [
      "s3:DeleteObject",
      "s3:DeleteObjectVersion",
      "s3:GetObject",
      "s3:GetObjectVersion",
      "s3:GetBucketPolicy",
      "s3:ListBucket",
      "s3:PutObject"
    ]

    resources = [
      module.s3_bucket[count.index].bucket.arn,
      "${module.s3_bucket[count.index].bucket.arn}/*"
    ]
  }
}

resource "aws_s3_bucket_policy" "ftp_user_access" {
  count  = local.build_s3 ? length(local.bucket_names) : 0
  bucket = module.s3_bucket[count.index].bucket.bucket
  policy = data.aws_iam_policy_document.bucket_policy[count.index].json
}