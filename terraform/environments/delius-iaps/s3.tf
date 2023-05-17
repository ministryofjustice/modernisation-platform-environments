# Legacy environment Log Archive bucket. Only needed in Production
# NEC requested we retain logs from the start of this year
module "s3-log-archive-bucket" { #tfsec:ignore:aws-s3-enable-versioning
  count = local.environment == "production" ? 1 : 0

  source    = "github.com/ministryofjustice/modernisation-platform-terraform-s3-bucket?ref=v6.4.0"
  providers = {
    aws.bucket-replication = aws
  }

  bucket_prefix      = "legacy-iaps-log-archive-"
  versioning_enabled = false
  bucket_policy      = [data.aws_iam_policy_document.log_archive_bucket_policy[0].json]
  # Enable bucket to be destroyed when not empty
  force_destroy = true

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
          }
      ]

      expiration = {
        days = 365
      }

      noncurrent_version_transition = [
        {
          days          = 90
          storage_class = "STANDARD_IA"
          }
      ]

      noncurrent_version_expiration = {
        days = 365
      }
    }
  ]

  tags = local.tags
}

data "aws_iam_policy_document" "log_archive_bucket_policy" {
  count = local.environment == "production" ? 1 : 0

  statement {
    effect = "Allow"
    actions = [
      "s3:GetObject",
      "s3:PutObject",
      "s3:ListBucket"
    ]
    resources = [
      "${module.s3-log-archive-bucket[0].bucket.arn}/*",
      module.s3-log-archive-bucket[0].bucket.arn
    ]
    principals {
      type        = "AWS"
      identifiers = ["*"]
    }
    condition {
      test     = "ForAnyValue:StringLike"
      variable = "aws:PrincipalOrgPaths"
      values   = ["${data.aws_organizations_organization.root_account.id}/*/${local.environment_management.modernisation_platform_organisation_unit_id}/*"]
    }
  }
}
