# Shared S3 server access logs bucket, managed in ccms-feasibility root
data "aws_s3_bucket" "s3_access_logs" {
  bucket = "${local.application_name}-s3-access-logs"
}

module "s3_dbbackup" {
  source = "github.com/ministryofjustice/modernisation-platform-terraform-s3-bucket?ref=v11.2.1"

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
      {
        Sid       = "DenyTLSOlderThan12"
        Effect    = "Deny"
        Principal = "*"
        Action    = "s3:*"
        Resource = [
          module.s3_dbbackup.bucket.arn,
          "${module.s3_dbbackup.bucket.arn}/*",
        ]
        Condition = {
          NumericLessThan = { "s3:TlsVersion" = "1.2" }
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

resource "aws_s3_bucket_logging" "s3_dbbackup" {
  bucket        = module.s3_dbbackup.bucket.id
  target_bucket = data.aws_s3_bucket.s3_access_logs.id
  target_prefix = "${module.s3_dbbackup.bucket.id}/"

  target_object_key_format {
    partitioned_prefix {
      partition_date_source = "EventTime"
    }
  }
}
