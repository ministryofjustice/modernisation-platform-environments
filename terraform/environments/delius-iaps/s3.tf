data "aws_iam_policy_document" "iaps_s3_policy" {
  statement {
    principals {
      type = "AWS"
      identifiers = [
        "arn:aws:iam::${local.environment_management.account_ids["core-shared-services-production"]}:role/ImageBuilder"
      ]
    }
    actions = [
      "s3:ListBucket",
      "s3:GetObject"
    ]
    resources = [
      "arn:aws:s3:::${local.artefact_bucket_name}",
      "arn:aws:s3:::${local.artefact_bucket_name}/*"
    ]
  }
}

module "s3_bucket" {
  count = local.environment == "development" ? 1 : 0

  source = "github.com/ministryofjustice/modernisation-platform-terraform-s3-bucket?ref=v6.2.0"

  providers = {
    aws.bucket-replication = aws
  }

  bucket_name        = local.artefact_bucket_name
  versioning_enabled = true

  lifecycle_rule = [
    {
      id      = "main"
      enabled = "Enabled"
      prefix  = ""

      tags = {
        rule      = "log"
        autoclean = "true"
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

  bucket_policy = [
    data.aws_iam_policy_document.iaps_s3_policy.json
  ]

  sse_algorithm = "AES256"

  tags = local.tags
}
