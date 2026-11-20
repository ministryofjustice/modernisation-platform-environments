module "s3_dbbackup" {
  source = "github.com/ministryofjustice/modernisation-platform-terraform-s3-bucket?ref=v11.2.0"

  bucket_name        = "${local.component_name}-${local.env_label}-dbbackup"
  versioning_enabled = false

  bucket_policy = [jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid       = "DenyInsecureTransport"
        Effect    = "Deny"
        Principal = "*"
        Action    = "s3:*"
        Resource = [
          module.s3_dbbackup.bucket.arn,
          "${module.s3_dbbackup.bucket.arn}/*",
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
      id      = "main"
      enabled = "Enabled"
      prefix  = ""

      tags = {
        rule      = "log"
        autoclean = "true"
      }

      expiration = {
        days = 30
      }

      noncurrent_version_expiration = {
        days = 30
      }

      abort_incomplete_multipart_upload_days = 6
    }
  ]

  tags = merge(local.tags, {
    Name = "${local.component_name}-${local.env_label}-dbbackup"
  })
}
