module "s3_bucket_migration" {

  source = "github.com/ministryofjustice/modernisation-platform-terraform-s3-bucket?ref=v7.0.0"

  providers = {
    aws.bucket-replication = aws.bucket-replication
  }

  bucket_prefix      = "${var.app_name}-${var.env_name}-ldap-"
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

  tags = merge(
    local.tags,
    {
      Name = "${var.env_name}-ldap-migration-s3-bucket"
    },
  )
}

# Create s3 bucket for deployment state
module "s3_bucket_app_deployment" {

  source = "github.com/ministryofjustice/modernisation-platform-terraform-s3-bucket?ref=v7.0.0"

  bucket_name        = "${var.app_name}-${var.env_name}-openldap-deployment"
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

  tags = local.tags
}
