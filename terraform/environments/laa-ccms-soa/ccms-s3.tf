############################
# S3 Bucket - CCMS SOA Shared
############################
module "s3-bucket-shared" {
  source = "github.com/ministryofjustice/modernisation-platform-terraform-s3-bucket?ref=9facf9fc8f8b8e3f93ffbda822028534b9a75399"

  bucket_name        = "${local.application_name}-${local.environment}-shared"
  versioning_enabled = true
  bucket_policy      = [aws_s3_bucket_policy.shared_bucket_policy.policy]
  sse_algorithm      = "AES256"
  custom_kms_key     = ""

  # Access logging into the existing logging bucket
  log_bucket = local.logging_bucket_name
  log_prefix = "s3access/${local.application_name}-${local.environment}-shared"

  # Replication disabled, same as EDRMS
  replication_enabled = false
  replication_region  = "eu-west-2"
  providers = {
    aws.bucket-replication = aws
  }

  # NO lifecycle transitions — only multipart cleanup
  lifecycle_rule = [
    {
      id      = "main"
      enabled = "Enabled"
      prefix  = ""

      tags = {
        rule      = "log"
        autoclean = "true"
      }

      abort_incomplete_multipart_upload_days = local.application_data.accounts[local.environment].s3_lifecycle_days_abort_incomplete_multipart_upload_days
    }
  ]

  tags = merge(local.tags,
    { Name = "${local.application_name}-${local.environment}-shared" }
  )
}

############################
# Policy for Shared Bucket
############################
resource "aws_s3_bucket_policy" "shared_bucket_policy" {
  bucket = module.s3-bucket-shared.bucket.id

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Sid    = "EnforceTLSv12orHigher",
        Effect = "Deny",
        Principal = {
          AWS = "*"
        },
        Action   = "s3:*",
        Resource = [
          "${module.s3-bucket-shared.bucket.arn}",
          "${module.s3-bucket-shared.bucket.arn}/*"
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

############################
# Create folders for Lambda deliveries
############################
resource "aws_s3_object" "folder" {
  bucket = module.s3-bucket-shared.bucket.id

  for_each = {
    for index, name in local.lambda_folder_name :
    name => index == 0 ? "${name}/" : "lambda_delivery/${name}/"
  }

  key = each.value
}
