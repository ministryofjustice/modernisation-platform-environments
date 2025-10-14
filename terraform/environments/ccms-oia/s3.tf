module "s3_ccms_oia" {
  source = "github.com/ministryofjustice/modernisation-platform-terraform-s3-bucket?ref=v9.0.0"

  bucket_name        = "${local.application_name}-${local.environment}"
  versioning_enabled = true
  ownership_controls = "BucketOwnerEnforced"

  lifecycle_rule = [
    {
      id      = "ccms_oia_lifecycle"
      enabled = "Enabled"
      prefix  = ""

      transition = [
        {
          days          = 90
          storage_class = "STANDARD_IA"
        },
        {
          days          = 365
          storage_class = "GLACIER"
        }
      ]

      noncurrent_version_transition = [
        {
          days          = 30
          storage_class = "STANDARD_IA"
        },
        {
          days          = 90
          storage_class = "GLACIER"
        }
      ]

      noncurrent_version_expiration = {
        days = 365
      }
    }
  ]

  tags = merge(local.tags,
    { Name = lower(format("%s-%s", local.application_name, local.environment)) }
  )

  providers = {
    aws.bucket-replication = aws
  }
}
