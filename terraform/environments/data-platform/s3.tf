
module "s3-bucket" { #tfsec:ignore:aws-s3-enable-versioning
  source = "github.com/ministryofjustice/modernisation-platform-terraform-s3-bucket?ref=v7.0.0"

  bucket_prefix      = "data-platform-products-${local.environment}"
  versioning_enabled = true
  # Refer to the below section "Replication" before enabling replication
  replication_enabled = false
  bucket_policy       = [data.aws_iam_policy_document.data_platform_product_bucket_policy_document.json]
  providers = {
    # Here we use the default provider Region for replication. Destination buckets can be within the same Region as the
    # source bucket. On the other hand, if you need to enable cross-region replication, please contact the Modernisation
    # Platform team to add a new provider for the additional Region.
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

module "s3_athena_query_results_bucket" { #tfsec:ignore:aws-s3-enable-versioning
  source = "github.com/ministryofjustice/modernisation-platform-terraform-s3-bucket?ref=v7.0.0"

  bucket_name        = "athena-data-product-query-results-${data.aws_caller_identity.current.account_id}"
  versioning_enabled = false
  # Refer to the below section "Replication" before enabling replication
  replication_enabled = false
  force_destroy       = true

  providers = {
    # Here we use the default provider Region for replication. Destination buckets can be within the same Region as the
    # source bucket. On the other hand, if you need to enable cross-region replication, please contact the Modernisation
    # Platform team to add a new provider for the additional Region.
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
          days          = 30
          storage_class = "STANDARD_IA"
          }, {
          days          = 90
          storage_class = "GLACIER"
        }
      ]

      expiration = {
        days = 365
      }

      noncurrent_version_transition = [
        {
          days          = 30
          storage_class = "STANDARD_IA"
          }, {
          days          = 90
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

resource "aws_s3_bucket_notification" "bucket_notification" {
  bucket      = module.s3-bucket.bucket.id
  eventbridge = true
}

# load the json schema for data product metadata
resource "aws_s3_object" "object" {
  bucket                 = module.s3-bucket.bucket.id
  key                    = "data_product_metadata_spec/v1.0.0/moj_data_product_metadata_spec.json"
  source                 = "data-product-metadata-json-schema/v1.0.0/moj_data_product_metadata_spec.json"
  etag                   = filemd5("data-product-metadata-json-schema/v1.0.0/moj_data_product_metadata_spec.json")
  acl                    = "bucket-owner-full-control"
  server_side_encryption = "AES256"
}
