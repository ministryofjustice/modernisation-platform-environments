module "s3_ccms_oia" {
  source = "github.com/ministryofjustice/modernisation-platform-terraform-s3-bucket?ref=v9.0.0"

  bucket_name        = "${local.application_name}-${local.environment}"
  versioning_enabled = true
  ownership_controls = "BucketOwnerEnforced"

  lifecycle_rule = [
    {
      id      = "ccms_oia_lifecycle"
      enabled = "Enabled"
      prefix  = ""

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

      noncurrent_version_transition = [
        {
          days          = 30
          storage_class = "STANDARD_IA"
        },
        {
          days          = 90
          storage_class = "GLACIER"
        }
      ]

      noncurrent_version_expiration = {
        days = 365
      }
    }
  ]

  tags = merge(local.tags,
    { Name = lower(format("%s-%s", local.application_name, local.environment)) }
  )

  providers = {
    aws.bucket-replication = aws
  }
}



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

#For shared bucket lifecycle rule is not needed as it host lambda application source code
resource "aws_s3_bucket" "ccms_oia_shared" {
  bucket = "${local.application_name}-${local.environment}-shared"

  tags = merge(local.tags,
    {
      Name = "${local.application_name}-${local.environment}-shared"
    }
  )

}


resource "aws_s3_object" "folder" {
  bucket = aws_s3_bucket.ccms_oia_shared.bucket
  for_each = {
    for index, name in local.lambda_folder_name :
    name => index == 0 ? "${name}/" : "lambda_delivery/${name}/"
  }

  key = each.value

}

resource "aws_s3_bucket_public_access_block" "ccms_oia_shared" {
  bucket                  = aws_s3_bucket.ccms_oia_shared.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_versioning" "ccms_oia_shared" {
  bucket = aws_s3_bucket.ccms_oia_shared.id

  versioning_configuration {
    status = "Enabled"
  }
}
