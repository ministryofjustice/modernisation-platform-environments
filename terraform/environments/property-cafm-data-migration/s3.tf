
# Landing bucket module
module "aws_s3_landing" {
  source      = "github.com/ministryofjustice/modernisation-platform-terraform-s3-bucket?ref=9facf9fc8f8b8e3f93ffbda822028534b9a75399"
  bucket_name = "property-datahub-landing-${local.environment}"

  bucket_policy = [jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        "Sid" : "RequireSSLRequests",
        "Effect" : "Deny",
        "Principal" : "*",
        "Action" : "s3:*",
        "Resource" : [
          module.aws_s3_landing.bucket.arn,
          "${module.aws_s3_landing.bucket.arn}/*"
        ],
        "Condition" : {
          "Bool" : {
            "aws:SecureTransport" : "false"
          }
        }
      },
      {
        Sid    = "AllowDeveloperAccessObjectLevel",
        Effect = "Allow",
        Principal = {
          AWS = [
            "arn:aws:iam::${local.environment_management.account_ids["property-cafm-data-migration-development"]}:role/developer",
            "arn:aws:iam::${local.environment_management.account_ids["property-cafm-data-migration-development"]}:role/sandbox",
            "arn:aws:iam::${local.environment_management.account_ids["property-cafm-data-migration-preproduction"]}:role/developer",
            "arn:aws:iam::${local.environment_management.account_ids["property-cafm-data-migration-preproduction"]}:role/migration",
            "arn:aws:iam::${local.environment_management.account_ids["property-cafm-data-migration-production"]}:role/developer",
            "arn:aws:iam::${local.environment_management.account_ids["property-cafm-data-migration-production"]}:role/migration"
          ]
        },
        Action = [
          "s3:GetObject",
          "s3:PutObject"
        ],
        Resource = "${module.aws_s3_landing.bucket.arn}/*"
      },
      {
        Sid    = "AllowAnalyticalPlatformIngestionService",
        Effect = "Allow",
        Principal = {
          AWS = [
            "arn:aws:iam::${local.environment_management.account_ids["analytical-platform-ingestion-development"]}:role/transfer",
            "arn:aws:iam::${local.environment_management.account_ids["analytical-platform-ingestion-production"]}:role/transfer"
          ]
        },
        Action = [
          "s3:DeleteObject",
          "s3:GetObject",
          "s3:GetObjectAcl",
          "s3:PutObject",
          "s3:PutObjectAcl",
          "s3:PutObjectTagging"
        ],
        Resource = [
          module.aws_s3_landing.bucket.arn,
          "${module.aws_s3_landing.bucket.arn}/*"
        ]
      }
    ]
  })]

  custom_kms_key      = aws_kms_key.shared_kms_key.arn
  versioning_enabled  = true
  ownership_controls  = "BucketOwnerEnforced"
  replication_enabled = false

  providers = {
    aws.bucket-replication = aws
  }

  tags = local.tags
}

# Enable AWS S3 server access logging for the landing bucket
resource "aws_s3_bucket_logging" "landing_bucket" {
  bucket        = module.aws_s3_landing.bucket.id
  target_bucket = module.s3_bucket_logs.bucket.id
  target_prefix = "landing/"
}

# Logging bucket module (used for access logs and query logs)
module "s3_bucket_logs" {
  source              = "github.com/ministryofjustice/modernisation-platform-terraform-s3-bucket?ref=9facf9fc8f8b8e3f93ffbda822028534b9a75399"
  bucket_prefix       = "${local.account_name}-bucket-logs-${local.environment_shorthand}-"
  versioning_enabled  = true
  ownership_controls  = "BucketOwnerEnforced"
  replication_enabled = false

  providers = {
    aws.bucket-replication = aws
  }

  lifecycle_rule = [
    {
      id      = "main"
      enabled = "Enabled"
      filter  = { prefix = "" }

      tags = {
        rule      = "log"
        autoclean = "true"
      }

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

      expiration = {
        days = 730
      }

      noncurrent_version_transition = [
        {
          days          = 90
          storage_class = "STANDARD_IA"
        },
        {
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

# Allow AWS S3 Logging service to write access logs to the logging bucket
resource "aws_s3_bucket_policy" "s3_logs_service" {
  bucket = module.s3_bucket_logs.bucket.id

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Sid       = "AllowS3LoggingService",
        Effect    = "Allow",
        Principal = { Service = "logging.s3.amazonaws.com" },
        Action    = "s3:PutObject",
        Resource  = "${module.s3_bucket_logs.bucket.arn}/*",
        Condition = {
          StringEquals = {
            "s3:x-amz-acl" = "bucket-owner-full-control"
          }
        }
      }
    ]
  })
}
