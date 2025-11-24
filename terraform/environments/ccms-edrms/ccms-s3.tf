

# S3 Bucket - Logging
module "s3-bucket-logging" {
  # v9.0.0 = https://github.com/ministryofjustice/modernisation-platform-terraform-s3-bucket/commit/9facf9fc8f8b8e3f93ffbda822028534b9a75399
  source = "github.com/ministryofjustice/modernisation-platform-terraform-s3-bucket?ref=9facf9fc8f8b8e3f93ffbda822028534b9a75399"

  bucket_name        = local.logging_bucket_name
  versioning_enabled = true
  bucket_policy      = [aws_s3_bucket_policy.lb_access_logs.policy]
  sse_algorithm      = "AES256"
  custom_kms_key     = ""

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
    { Name = lower(format("s3-%s-%s-logging", local.application_name, local.environment)) }
  )
}

resource "aws_s3_bucket_policy" "lb_access_logs" {
  bucket = module.s3-bucket-logging.bucket.id

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
        Resource = ["${module.s3-bucket-logging.bucket.arn}/*", "${module.s3-bucket-logging.bucket.arn}"],
        Condition = {
          NumericLessThan = {
            "s3:TlsVersion" = "1.2"
          }
        }
      },
      {
        Sid    = "AllowELBLogDeliveryPutObject",
        Effect = "Allow",
        Principal = {
          Service = [
            "logdelivery.elasticloadbalancing.amazonaws.com"
          ]
        },
        Action   = ["s3:PutObject"],
        Resource = "${module.s3-bucket-logging.bucket.arn}/*",
        Condition = {
          StringEquals = {
            "s3:x-amz-acl"      = "bucket-owner-full-control",
            "aws:SourceAccount" = data.aws_caller_identity.current.account_id
          }
        }
      }
    ]
  })
}

# S3 Bucket - Logging
module "s3-bucket-shared" {
  # v9.0.0 = https://github.com/ministryofjustice/modernisation-platform-terraform-s3-bucket/commit/9facf9fc8f8b8e3f93ffbda822028534b9a75399
  source = "github.com/ministryofjustice/modernisation-platform-terraform-s3-bucket?ref=9facf9fc8f8b8e3f93ffbda822028534b9a75399"

  bucket_name        = "${local.application_name}-${local.environment}-shared"
  versioning_enabled = true
  bucket_policy      = [aws_s3_bucket_policy.shared_bucket_policy.policy]
  sse_algorithm      = "AES256"
  custom_kms_key     = ""

  log_bucket = local.logging_bucket_name
  log_prefix = "s3access/${local.application_name}-${local.environment}-shared"

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

  lifecycle_rule = []


  tags = merge(local.tags,
    { Name = "${local.application_name}-${local.environment}-shared" }
  )
}

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
        Resource = ["${module.s3-bucket-shared.bucket.arn}/*", "${module.s3-bucket-shared.bucket.arn}"],
        Condition = {
          NumericLessThan = {
            "s3:TlsVersion" = "1.2"
          }
        }
      }
    ]
  })
}

resource "aws_s3_object" "folder" {
  bucket = module.s3-bucket-shared.bucket.id

  for_each = {
    for index, name in local.lambda_folder_name :
    name => index == 0 ? "${name}/" : "lambda_delivery/${name}/"
  }

  key = each.value

}