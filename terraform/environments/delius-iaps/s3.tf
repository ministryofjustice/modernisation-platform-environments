data "aws_iam_policy_document" "iaps_s3_policy" {
  statement {
    principals {
      type        = "AWS"
      identifiers = ["arn:aws:iam::*:role/iaps_ec2_role"]
    }
    actions   = ["s3:GetObject"]
    resources = ["*"]
  }
}

module "s3_bucket" {
  source = "github.com/ministryofjustice/modernisation-platform-terraform-s3-bucket?ref=v6.2.0"
  count  = 0
  providers = {
    aws.bucket-replication = aws
  }

  bucket_prefix      = "iaps-artifacts-"
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

  tags = local.tags
}
