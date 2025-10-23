# S3 Bucket - Logging
module "s3-bucket-logging" {
  # v9.0.0 = https://github.com/ministryofjustice/modernisation-platform-terraform-s3-bucket/commit/9facf9fc8f8b8e3f93ffbda822028534b9a75399
  source = "github.com/ministryofjustice/modernisation-platform-terraform-s3-bucket?ref=9facf9fc8f8b8e3f93ffbda822028534b9a75399"

  bucket_name        = local.logging_bucket_name
  versioning_enabled = true
  bucket_policy      = [data.aws_iam_policy_document.logging_s3_policy.json]

  log_bucket = local.logging_bucket_name
  log_prefix = "s3access/${local.logging_bucket_name}"

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
    { Name = lower(format("s3-%s-%s-logging", "${local.application_data.accounts[local.environment].app_name}", local.environment)) }
  )
}

# resource "aws_s3_bucket_notification" "logging_bucket_notification" {
#   bucket = module.s3-bucket-logging.bucket.id

#   topic {
#     topic_arn     = aws_sns_topic.s3_topic.arn
#     events        = ["s3:ObjectCreated:*"]
#     filter_suffix = ".log"
#   }
# }

data "aws_iam_policy_document" "logging_s3_policy" {
  statement {
    effect = "Allow"
      principals {
        type     = "Service"
        identifiers = ["logdelivery.elasticloadbalancing.amazonaws.com"]
      },
    actions   = ["s3:PutObject"]
    resources = ["${module.s3-bucket-logging.bucket.arn}/*"]
  }
  statement {
    effect = "Allow"
    principals {
      type        = "Service"
      identifiers = ["logging.s3.amazonaws.com"]
    }
    actions   = ["s3:PutObject"]
    resources = ["arn:aws:s3:::${local.application_data.accounts[local.environment].app_name}-${local.environment}-logging/*"]
    condition {
      test     = "StringEquals"
      variable = "aws:SourceAccount"
      values   = ["${data.aws_caller_identity.current.account_id}"]
    }
  }
}