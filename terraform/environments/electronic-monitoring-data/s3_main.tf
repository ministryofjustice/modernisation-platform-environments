# ------------------------------------------------------------------------
# Metadata Store Bucket
# ------------------------------------------------------------------------

module "metadata-s3-bucket" {
    source = "github.com/ministryofjustice/modernisation-platform-terraform-s3-bucket?ref=f109c88"

  bucket_prefix                            = "metadata-store-"
  versioning_enabled                       = true

  # to disable ACLs in preference of BucketOwnership controls as per https://aws.amazon.com/blogs/aws/heads-up-amazon-s3-security-changes-are-coming-in-april-of-2023/ set:
  ownership_controls = "BucketOwnerEnforced"

  # Refer to the below section "Replication" before enabling replication
  replication_enabled                      = false
  # Below two variables and providers configuration are only relevant if 'replication_enabled' is set to true
  # replication_region                       = "eu-west-2"
  # replication_role_arn                     = module.s3-bucket.role.arn
  providers = {
    # Here we use the default provider Region for replication. Destination buckets can be within the same Region as the
    # source bucket. On the other hand, if you need to enable cross-region replication, please contact the Modernisation
    # Platform team to add a new provider for the additional Region.
    # Leave this provider block in even if you are not using replication
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

  tags                 = merge(local.tags, {Resource_Type="metadata_store"})
}

resource "aws_s3_bucket_notification" "send_metadata_to_ap" {
  bucket = module.metadata-s3-bucket.bucket.id

  lambda_function {
    id                  = "metadata_bucket_notification"
    lambda_function_arn = module.send_metadata_to_ap.lambda_function_arn
    events              = ["s3:ObjectCreated:*"]
    filter_suffix       = ".json"
  }

  depends_on = [aws_lambda_permission.send_metadata_to_ap]
}