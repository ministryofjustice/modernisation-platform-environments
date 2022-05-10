module "s3-bucket-ukcloud-replica" {
  count = local.is-development ? 1 : 0

  source              = "github.com/ministryofjustice/modernisation-platform-terraform-s3-bucket?ref=v6.0.5"
  bucket_prefix       = "s3-bucket-ukcloud-replica"
  versioning_enabled  = false
  replication_enabled = false
  # The following providers configuration will not be used because 'replication_enabled' is false
  providers           = {
    aws.bucket-replication = aws
  }

  lifecycle_rule = [
    {
      id      = "tmp"
      enabled = "Enabled"
      prefix  = "/tmp"

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
  count = local.is-development ? 1 : 0
  statement {
    effect    = "Allow"
    actions   = [
      "s3:Get*",
    ]
    resources = [
      module.s3-bucket-ukcloud-replica[0].bucket.id,
      "${module.s3-bucket-ukcloud-replica[0].bucket.id}/*"
    ]
    principals {
      type        = "AWS"
      identifiers = [
        "arn:aws:iam::${local.environment_management.account_ids["equip-production"]}:*"
      ]
    }
  }
}
