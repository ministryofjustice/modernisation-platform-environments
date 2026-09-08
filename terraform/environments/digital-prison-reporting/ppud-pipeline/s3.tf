# policy to allow replication in destination bucket
data "aws_iam_policy_document" "ppud_replication_destination_bucket_policy" {
  count = local.is-development ? 1 : 0

  statement {
    sid    = "Set-permissions-for-objects"
    effect = "Allow"

    actions = [
      "s3:ReplicateObject"
    ]
    resources = ["arn:aws:s3:::${module.ppud_replication_destination[0].bucket.id}/*"]
    principals {
      type = "AWS"
      identifiers = [
        "arn:aws:iam::${local.environment_management.account_ids["ppud-${local.environment}"]}:role/service-role/iam_role_s3_bucket_moj_database_source_dev"
      ]
    }
  }

  statement {
    sid    = "Set-permissions-on-bucket"
    effect = "Allow"

    actions = [
      "s3:GetBucketVersioning",
      "s3:PutBucketVersioning"
    ]
    resources = ["arn:aws:s3:::${module.ppud_replication_destination[0].bucket.id}"]

    principals {
      type = "AWS"
      identifiers = [
        "arn:aws:iam::${local.environment_management.account_ids["ppud-${local.environment}"]}:role/service-role/iam_role_s3_bucket_moj_database_source_dev"
      ]
    }
  }
}

# S3 destination bucket for .bak file replication from ppud AWS account
module "ppud_replication_destination" {
  count = local.is-test ? 0 : 1

  # v11.1.0
  source = "git::https://github.com/ministryofjustice/modernisation-platform-terraform-s3-bucket?ref=66bd5c6aa0d0396442f0d4a63642029ff38d2a8a"

  bucket_prefix      = "ppud-bak-replication-${local.environment}"
  bucket_namespace   = "account-regional"
  versioning_enabled = true

  ownership_controls = "BucketOwnerEnforced"

  replication_enabled = false
  providers = {
    aws.bucket-replication = aws
  }

  sse_algorithm = "AES256"

  bucket_policy = local.is-development ? [data.aws_iam_policy_document.ppud_replication_destination_bucket_policy[0].json] : []

  lifecycle_rule = [
    {
      id      = "main"
      enabled = "Enabled"
      prefix  = ""

      transition = [
        {
          days          = 60
          storage_class = "INTELLIGENT_TIERING"
        }
      ]

      noncurrent_version_transition = [
        {
          days          = 30
          storage_class = "INTELLIGENT_TIERING"
        }
      ]

      noncurrent_version_expiration = {
        days = 730
      }
    }
  ]

  tags = merge(
    local.tags,
    {
      resource-type = "S3 Bucket"
    }
  )

}
