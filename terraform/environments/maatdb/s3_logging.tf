module "s3-bucket-logging" {
  source = "github.com/ministryofjustice/modernisation-platform-terraform-s3-bucket?ref=81230d03816f140ae912454815ec531d7cbe2c8e" # v11.2.0

  bucket_name        = "${local.application_name}-${local.environment}-logging"
  versioning_enabled = true
  bucket_policy = [jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Sid       = "DenyInsecureTransport",
        Effect    = "Deny",
        Principal = "*",
        Action    = "s3:*",
        Resource  = ["${module.s3-bucket-shared.bucket.arn}/*", module.s3-bucket-shared.bucket.arn],
        Condition = {
          Bool = {
            "aws:SecureTransport" = "false"
          }
        }
      },
      {
        Sid    = "EnforceTLSv12orHigher",
        Effect = "Deny",
        Principal = {
          AWS = "*"
        },
        Action   = "s3:*",
        Resource = ["${module.s3-bucket-shared.bucket.arn}/*", module.s3-bucket-shared.bucket.arn],
        Condition = {
          NumericLessThan = {
            "s3:TlsVersion" = "1.2"
          }
        }
      },
    {
      Sid     = "AllowS3Logging Shared Bucket"
      Effect  = "Allow"
      Actions = ["s3:PutObject"]
      Principal = {
        AWS = "*"
      }
      Resource = [
        "${module.s3-bucket-logging.bucket.arn}/*",
        module.s3-bucket-logging.bucket.arn
      ]
      Condition = {
        StringLike = {
          "aws:SourceArn" = module.s3-bucket-shared.bucket.arn
        }
      }
    },
    {
      Sid     = "AllowS3Logging FTP Buckets"
      Effect  = "Allow"
      Actions = ["s3:PutObject"]
      Principal = {
        AWS = "*"
      }
      Resource = [
        "${module.s3-bucket-logging.bucket.arn}/*",
        module.s3-bucket-logging.bucket.arn
      ]

      Condition = {
        StringLike = {
          "aws:SourceArn" = flatten([
            for ftp_bucket in values(module.s3_bucket) : [
              ftp_bucket.bucket.arn
            ]
          ])
        }
      }
    }
  ]
  })]

  sse_algorithm  = "AES256"
  custom_kms_key = ""
  # Refer to the below section "Replication" before enabling replication
  replication_enabled = false
  # Below three variables and providers configuration are only relevant if 'replication_enabled' is set to true
  replication_region = "eu-west-2"
  # replication_role_arn                     = module.s3-bucket-replication-role.role.arn
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

      expiration = {
        days = local.application_data.accounts[local.environment].s3_lifecycle_days_expiration_current_logs
      }

      noncurrent_version_expiration = {
        days = local.application_data.accounts[local.environment].s3_lifecycle_days_expiration_noncurrent_logs
      }

      abort_incomplete_multipart_upload_days = local.application_data.accounts[local.environment].s3_lifecycle_days_abort_incomplete_multipart_upload_days
    }
  ]

  tags = merge(local.tags,
    { Name = "${local.application_name}-${local.environment}-logging" }
  )
}