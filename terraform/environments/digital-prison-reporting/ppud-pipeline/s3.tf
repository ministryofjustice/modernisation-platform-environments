# S3 destination bucket for .bak file replication from ppud AWS account
module "ppud_replication_destination" {

  # v11.1.0
  source = "git::https://github.com/ministryofjustice/modernisation-platform-terraform-s3-bucket?ref=66bd5c6aa0d0396442f0d4a63642029ff38d2a8a"

  bucket_prefix      = "ppud-bak-replication"
  bucket_namespace   = "account-regional"
  versioning_enabled = true

  ownership_controls = "BucketOwnerEnforced"

  replication_enabled = false
  providers = {
    aws.bucket-replication = aws
  }

  sse_algorithm = "AES256"

  lifecycle_rule = [
    {
      id      = "main"
      enabled = "Disabled"
      prefix  = ""

      transition = [
        {
          days          = 60
          storage_class = "INTELLIGENT_TIERING"
        }
      ]

      noncurrent_version_transition = [
        {
          days          = 30
          storage_class = "INTELLIGENT_TIERING"
        }
      ]

      noncurrent_version_expiration = {
        days = 730
      }
    }
  ]

  tags = merge(
    local.tags,
    {
      resource-type = "S3 Bucket"
    }
  )

}
