module "s3_pui_docs" {
  source = "github.com/ministryofjustice/modernisation-platform-terraform-s3-bucket?ref=v9.0.0"

  bucket_name        = "${local.application_name}-docs-${local.environment}"
  versioning_enabled = true
  ownership_controls = "BucketOwnerEnforced"

  lifecycle_rule = [
    {
      id      = "pui_docs_lifecycle"
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
    { Name = lower(format("%s-docs-%s", local.application_name, local.environment)) }
  )

  providers = {
    aws.bucket-replication = aws
  }
}