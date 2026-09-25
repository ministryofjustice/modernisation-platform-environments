module "s3-bucket-logging" {
  source = "github.com/ministryofjustice/modernisation-platform-terraform-s3-bucket?ref=81230d03816f140ae912454815ec531d7cbe2c8e" # v11.2.0

  bucket_name         = "${local.application_name}-${local.environment}-logging"
  versioning_enabled = true
  sse_algorithm      = "AES256"
  custom_kms_key     = ""
  bucket_policy      = [aws_s3_bucket_policy.logging_bucket_policy.policy]

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

      abort_incomplete_multipart_upload_days = 6
      expiration = {
        days = 90
      }
      noncurrent_version_expiration = {
        days = 90
      }
  }]

  tags = merge(local.tags,
    { Name = "${local.application_name}-${local.environment}-logging" }
  )
}

resource "aws_s3_bucket_policy" "logging_bucket_policy" {
    bucket = module.s3-bucket-logging.bucket.id
    policy = jsonencode({
        Version = "2012-10-17",
    Statement = [
      {
        "Sid" : "DenyInsecureTransport",
        "Effect" : "Deny",
        "Principal" : "*",
        "Action" : "s3:*",
        "Resource" : [
          "${module.s3-bucket-logging.bucket.arn}/*",
          module.s3-bucket-logging.bucket.arn
        ],
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
          "${module.s3-bucket-logging.bucket.arn}/*",
          module.s3-bucket-logging.bucket.arn
        ],
        Condition = {
          NumericLessThan = {
            "s3:TlsVersion" = "1.2"
          }
        }
      }
    ]
    })
}