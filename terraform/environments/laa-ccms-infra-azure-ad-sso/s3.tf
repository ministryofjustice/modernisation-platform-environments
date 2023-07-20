#------------------------------------------------------------------------------
# S3 Bucket - Logging
#------------------------------------------------------------------------------
module "s3-bucket-logging" {
  source = "github.com/ministryofjustice/modernisation-platform-terraform-s3-bucket?ref=v6.4.0"

  bucket_name        = local.logging_bucket_name
  versioning_enabled = false
  bucket_policy_v2 = [{
    effect    = "Allow"
    actions   = ["s3:PutObject"]
    resources = ["${module.s3-bucket-logging.bucket.arn}/*"]
    principals = {
      type        = "AWS"
      identifiers = ["arn:aws:iam::652711504416:root"]
    }
  }]

  ownership_controls = "BucketOwnerEnforced" # Disable all S3 bucket ACL


  log_bucket = local.logging_bucket_name
  log_prefix = "s3access/${local.logging_bucket_name}"


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
          days          = 90
          storage_class = "STANDARD_IA"
          }, {
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
          }, {
          days          = 365
          storage_class = "GLACIER"
        }
      ]

      noncurrent_version_expiration = {
        days = 730
      }
    }
  ]

  tags = merge(local.tags,
    { Name = lower(format("s3-%s-%s-logging", local.application_name, local.environment)) }
  )
}

#resource "aws_s3_bucket_acl" "ebs-vision-db-logging-bucket" {
#  bucket = local.logging_bucket_name
#  acl    = "private"
#}
#
#resource "aws_s3_bucket_ownership_controls" "ebs-vision-db-logging-bucket-ownership" {
#  bucket = local.logging_bucket_name
#  rule {
#    object_ownership = "BucketOwnerEnforced"
#  }
#}
resource "aws_s3_bucket_notification" "logging_bucket_notification" {
  bucket = module.s3-bucket-logging.bucket.id

  topic {
    topic_arn     = aws_sns_topic.s3_topic.arn
    events        = ["s3:ObjectCreated:*"]
    filter_suffix = ".log"
  }
}

