module "s3_bucket_migration" {

  source = "github.com/ministryofjustice/modernisation-platform-terraform-s3-bucket?ref=v6.4.0"

  providers = {
    aws.bucket-replication = aws
  }

  bucket_prefix      = "${local.application_name}-${local.environment}-ldap-"
  versioning_enabled = true
  sse_algorithm      = "AES256"
  # Useful guide - https://aws.amazon.com/blogs/storage/how-to-use-aws-datasync-to-migrate-data-between-amazon-s3-buckets/
  bucket_policy_v2 = [{
    effect = "Allow"
    actions = [
      "s3:GetBucketLocation",
      "s3:ListBucket",
      "s3:ListBucketMultipartUploads",
      "s3:AbortMultipartUpload",
      "s3:DeleteObject",
      "s3:GetObject",
      "s3:ListMultipartUploadParts",
      "s3:PutObject",
      "s3:GetObjectTagging",
      "s3:PutObjectTagging"
    ]
    principals = {
      type = "AWS"
      identifiers = [
        "arn:aws:iam::${local.application_data.accounts[local.environment].migration_source_account_id}:role/ldap-data-migration-lambda-role"
      ]
    }
    },
    {
      effect  = "Allow"
      actions = ["s3:ListBucket"]
      principals = {
        type = "AWS"
        identifiers = [
          "arn:aws:iam::${local.application_data.accounts[local.environment].migration_source_account_id}:role/terraform"
        ]
      }
    },
    {
      effect  = "Allow"
      actions = ["s3:ListBucket"]
      principals = {
        type = "AWS"
        identifiers = [
          "arn:aws:iam::${local.application_data.accounts[local.environment].migration_source_account_id}:role/admin"
        ]
      }
    }
  ]

  ownership_controls = "BucketOwnerEnforced" # Disable all S3 bucket ACL

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
          days          = 120
          storage_class = "STANDARD_IA"
          }, {
          days          = 180
          storage_class = "GLACIER"
        }
      ]

      noncurrent_version_expiration = {
        days = 365
      }
    }
  ]

  tags = local.tags
}
