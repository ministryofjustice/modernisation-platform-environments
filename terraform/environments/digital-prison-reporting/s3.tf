### S3 KMS
resource "aws_kms_key" "s3" {
  description         = "Encryption key for s3"
  enable_key_rotation = true
  key_usage           = "ENCRYPT_DECRYPT"
  policy              = data.aws_iam_policy_document.s3-kms.json
  is_enabled          = true


  tags = merge(
    local.tags,
    {
      Name = "${local.application_name}-s3-kms"
    }
  )
}

data "aws_iam_policy_document" "s3-kms" {
  statement {
    effect    = "Allow"
    actions   = ["kms:*"]
    resources = ["aws_kms_key.s3.arn"]

    principals {
      type        = "AWS"
      identifiers = ["arn:aws:iam::${data.aws_caller_identity.current.account_id}:root", "arn:aws:iam::${data.aws_caller_identity.current.account_id}:user/cicd-member-user"]
    }
  }
}

resource "aws_kms_alias" "kms-alias" {
  name          = "alias/s3"
  target_key_id = aws_kms_key.s3.arn
}

### S3 Bucket
resource "random_uuid" "s3_uuid" {}

module "s3-bucket" {
  source = "git::https://github.com/ministryofjustice/modernisation-platform-terraform-s3-bucket?ref=v6.2.0"

  providers = {
    aws.bucket-replication = aws
  }
  bucket_prefix = "dpr-demo-${random_uuid.s3_uuid.result}-local.environment}"

  replication_enabled = false
  custom_kms_key      = aws_kms_key.s3.arn
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