module "laa_oem_logging" {
  source = "github.com/ministryofjustice/modernisation-platform-terraform-s3-bucket?ref=81230d03816f140ae912454815ec531d7cbe2c8e" # v11.2.0

  bucket_name = "${local.application_name}-${local.environment}-logging"

  versioning_enabled = true
  bucket_policy      = [aws_s3_bucket_policy.laa_oem_logging.policy]
  sse_algorithm      = "AES256"
  custom_kms_key     = ""

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

      transition = [
        {
          days          = local.application_data.accounts[local.environment].s3_lifecycle_days_transition_current_standard
          storage_class = "STANDARD_IA"
          }, {
          days          = local.application_data.accounts[local.environment].s3_lifecycle_days_transition_current_glacier
          storage_class = "GLACIER"
        }
      ]

      expiration = {
        days = local.application_data.accounts[local.environment].s3_lifecycle_days_expiration_current
      }

      noncurrent_version_transition = [
        {
          days          = local.application_data.accounts[local.environment].s3_lifecycle_days_transition_noncurrent_standard
          storage_class = "STANDARD_IA"
          }, {
          days          = local.application_data.accounts[local.environment].s3_lifecycle_days_transition_noncurrent_glacier
          storage_class = "GLACIER"
        }
      ]

      noncurrent_version_expiration = {
        days = local.application_data.accounts[local.environment].s3_lifecycle_days_expiration_noncurrent
      }

      abort_incomplete_multipart_upload_days = local.application_data.accounts[local.environment].s3_lifecycle_days_abort_incomplete_multipart_upload_days
    }
  ]

  tags = merge(local.tags,
    { Name = lower(format("s3-%s-%s-logging", local.application_name, local.environment)) }
  )
}

resource "aws_s3_bucket_policy" "laa_oem_logging" {
  bucket = module.laa_oem_logging.bucket.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        "Sid" : "DenyInsecureTransport",
        "Effect" : "Deny",
        "Principal" : "*",
        "Action" : "s3:*",
        "Resource" : [
          "${module.laa_oem_logging.bucket.arn}/*",
        module.laa_oem_logging.bucket.arn],
        "Condition" : {
          "Bool" : {
            "aws:SecureTransport" : "false"
          }
        }
      },
      {
        Sid    = "EnforceTLSv12orHigher",
        Effect = "Deny",
        Principal = {
          AWS = "*"
        },
        Action = "s3:*",
        Resource = [
          "${module.laa_oem_logging.bucket.arn}/*",
          module.laa_oem_logging.bucket.arn
        ],
        Condition = {
          Bool = {
            "aws:SecureTransport" = "false"
          }
          NumericLessThan = {
            "s3:TlsVersion" = "1.2"
          }
        }
      },
      {
        Sid    = "AllowS3Logging Shared Bucket",
        Effect = "Allow",
        Principal = {
          Service = "logging.s3.amazonaws.com"
        },
        Action = "s3:PutObject",
        Resource = [
          "${module.laa_oem_logging.bucket.arn}/*",
          module.laa_oem_logging.bucket.arn
        ],
        Condition = {
          ArnLike = {
            "aws:SourceArn" = aws_s3_bucket.laa_oem_shared.arn
          }
        }
      }
    ]
  })
}