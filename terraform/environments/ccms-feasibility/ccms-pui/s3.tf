module "s3_docs" {
  source = "github.com/ministryofjustice/modernisation-platform-terraform-s3-bucket?ref=v9.0.0"

  bucket_name        = local.docs_bucket_name
  versioning_enabled = true
  ownership_controls = "BucketOwnerEnforced"

  bucket_policy = [jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid       = "DenyInsecureTransport"
        Effect    = "Deny"
        Principal = "*"
        Action    = "s3:*"
        Resource = [
          module.s3_docs.bucket.arn,
          "${module.s3_docs.bucket.arn}/*",
        ]
        Condition = {
          Bool = { "aws:SecureTransport" = "false" }
        }
      },
    ]
  })]

  replication_enabled = false
  replication_region  = "eu-west-2"

  providers = {
    aws.bucket-replication = aws
  }

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

      abort_incomplete_multipart_upload_days = 6
    }
  ]

  tags = merge(local.tags, {
    Name = local.docs_bucket_name
  })
}
