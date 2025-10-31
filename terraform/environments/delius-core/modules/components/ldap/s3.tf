module "s3_bucket_migration" {
  #checkov:skip=CKV_TF_1

  source = "github.com/ministryofjustice/modernisation-platform-terraform-s3-bucket?ref=v9.0.0"

  providers = {
    aws.bucket-replication = aws.bucket-replication
  }

  bucket_prefix      = "ldap-${var.env_name}-migration"
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
        "arn:aws:iam::${var.ldap_config.migration_source_account_id}:role/${var.ldap_config.migration_lambda_role}"
      ]
    }
    },
    {
      effect  = "Allow"
      actions = ["s3:ListBucket"]
      principals = {
        type = "AWS"
        identifiers = [
          "arn:aws:iam::${var.ldap_config.migration_source_account_id}:role/terraform"
        ]
      }
    },
    {
      effect  = "Allow"
      actions = ["s3:ListBucket"]
      principals = {
        type = "AWS"
        identifiers = [
          "arn:aws:iam::${var.ldap_config.migration_source_account_id}:role/admin"
        ]
      }
    },
    {
      effect = "Allow"
      actions = [
        "s3:GetObject",
        "s3:ListBucket"
      ]
      principals = {
        type = "AWS"
        identifiers = [
          var.task_role_arn
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

  tags = var.tags
}

# Create s3 bucket for deployment state
module "s3_bucket_app_deployment" {
  #checkov:skip=CKV_TF_1

  source = "github.com/ministryofjustice/modernisation-platform-terraform-s3-bucket?ref=v9.0.0"

  bucket_prefix      = "ldap-${var.env_name}-deployment-state"
  versioning_enabled = true

  providers = {
    aws.bucket-replication = aws.bucket-replication
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

  tags = var.tags
}
