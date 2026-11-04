############################
# S3 Bucket - CCMS SOA Shared
############################
module "s3-bucket-shared" {
  # v11.2.0 = https://github.com/ministryofjustice/modernisation-platform-terraform-s3-bucket/commit/81230d03816f140ae912454815ec531d7cbe2c8e
  source = "github.com/ministryofjustice/modernisation-platform-terraform-s3-bucket?ref=81230d03816f140ae912454815ec531d7cbe2c8e"

  bucket_name        = "${local.application_name}-${local.environment}-shared"
  versioning_enabled = true
  bucket_policy = [
    jsonencode({
      Version = "2012-10-17",
      Statement = [
        {
          Sid    = "EnforceTLSv12orHigher",
          Effect = "Deny",
          Principal = {
            AWS = "*"
          },
          Action = "s3:*",
          Resource = [
            module.s3-bucket-shared.bucket.arn,
            "${module.s3-bucket-shared.bucket.arn}/*"
          ],
          Condition = {
            NumericLessThan = {
              "s3:TlsVersion" = "1.2"
            }
          }
        }
      ]
  })]
  sse_algorithm  = "AES256"
  custom_kms_key = ""

  # Access logging into the existing logging bucket
  log_buckets = {
    log_bucket_name = module.s3-bucket-logging.bucket.id
    log_bucket_arn  = module.s3-bucket-logging.bucket.arn
  }
  manage_log_bucket_policy = false

  log_prefix                = "s3access/"
  log_partition_date_source = "EventTime"

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
