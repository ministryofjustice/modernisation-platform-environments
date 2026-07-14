
# ---------------------------------------------
# S3 Bucket - Logging
# ---------------------------------------------
module "s3-bucket-logging" {
  # v8.2.0 = https://github.com/ministryofjustice/modernisation-platform-terraform-s3-bucket/commit/52a40b0dd18aaef0d7c5565d93cc8997aad79636
  source = "github.com/ministryofjustice/modernisation-platform-terraform-s3-bucket?ref=52a40b0dd18aaef0d7c5565d93cc8997aad79636"

  bucket_name        = local.logging_bucket_name
  versioning_enabled = true
  bucket_policy = [jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        "Sid" : "DenyInsecureTransport",
        "Effect" : "Deny",
        "Principal" : "*",
        "Action" : "s3:*",
        "Resource" : [
          module.s3-bucket-logging.bucket.arn,
          "${module.s3-bucket-logging.bucket.arn}/*"
        ],
        "Condition" : {
          "Bool" : {
            "aws:SecureTransport" : "false"
          }
        }
      },
      {
        Sid    = "AllowELBLogDeliveryPutObject"
        Effect = "Allow"
        Principal = {
          Service = "logdelivery.elasticloadbalancing.amazonaws.com"
        }
        Action   = "s3:PutObject"
        Resource = "${module.s3-bucket-logging.bucket.arn}/*"
        Condition = {
          StringEquals = {
            "aws:SourceAccount" = data.aws_caller_identity.current.account_id
            "s3:x-amz-acl"      = "bucket-owner-full-control"
          }
        }
      },
      {
        Effect = "Allow"
        Principal = {
          Service = "logging.s3.amazonaws.com"
        }
        Action   = "s3:PutObject"
        Resource = "arn:aws:s3:::ccms-ebs-${local.environment}-logging/*"
        Condition = {
          StringEquals = {
            "aws:SourceAccount" = data.aws_caller_identity.current.account_id
          }
        }
      },
      {
        "Sid" = "RestrictToTLSRequestsOnly",
        "Action" : "s3:*",
        "Effect" : "Deny",
        "Resource" : [
          module.s3-bucket-logging.bucket.arn,
          "${module.s3-bucket-logging.bucket.arn}/*"
        ],
        "Condition" : {
          "Bool" : {
            "aws:SecureTransport" : "false"
          },
          "NumericLessThan" : {
            "aws:TLSVersion" : "1.2"
          }
        },
        "Principal" : "*"
      }
    ]
  })]

  log_bucket    = local.logging_bucket_name
  log_prefix    = "s3access/${local.logging_bucket_name}"
  sse_algorithm = "AES256"

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


resource "aws_s3_bucket_notification" "logging_bucket_notification" {
  bucket      = module.s3-bucket-logging.bucket.id
  eventbridge = true
  topic {
    topic_arn     = aws_sns_topic.s3_topic.arn
    events        = ["s3:ObjectCreated:*"]
    filter_suffix = ".log"
  }
}

# ---------------------------------------------
# S3 Bucket - R-sync
# ---------------------------------------------
module "s3-bucket-dbbackup" {
  # v8.2.0 = https://github.com/ministryofjustice/modernisation-platform-terraform-s3-bucket/commit/52a40b0dd18aaef0d7c5565d93cc8997aad79636
  source = "github.com/ministryofjustice/modernisation-platform-terraform-s3-bucket?ref=52a40b0dd18aaef0d7c5565d93cc8997aad79636"

  bucket_name        = local.rsync_bucket_name
  versioning_enabled = true
  bucket_policy = [jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        "Sid" : "DenyInsecureTransport",
        "Effect" : "Deny",
        "Principal" : "*",
        "Action" : "s3:*",
        "Resource" : [
          module.s3-bucket-dbbackup.bucket.arn,
          "${module.s3-bucket-dbbackup.bucket.arn}/*"
        ],
        "Condition" : {
          "Bool" : {
            "aws:SecureTransport" : "false"
          }
        }
      },
      {
        Effect = "Allow"
        Principal = {
          AWS = [
            "arn:aws:iam::${local.environment_management.account_ids["core-shared-services-production"]}:root",
            "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/developer"
          ]
        }
        Action   = "s3:PutObject"
        Resource = "${module.s3-bucket-dbbackup.bucket.arn}/*"
      },
      {
        "Sid" = "RestrictToTLSRequestsOnly",
        "Action" : "s3:*",
        "Effect" : "Deny",
        "Resource" : [
          module.s3-bucket-dbbackup.bucket.arn,
          "${module.s3-bucket-dbbackup.bucket.arn}/*"
        ],
        "Condition" : {
          "Bool" : {
            "aws:SecureTransport" : "false"
          },
          "NumericLessThan" : {
            "aws:TLSVersion" : "1.2"
          }
        },
        "Principal" : "*"
      }
    ]
  })]

  log_bucket = local.logging_bucket_name
  log_prefix = "s3access/${local.rsync_bucket_name}"

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
        days = local.application_data.accounts[local.environment].rman_s3_lifecycle_days_expiration_current
      }

      noncurrent_version_expiration = {
        days = local.application_data.accounts[local.environment].rman_s3_lifecycle_days_expiration_noncurrent
      }

      abort_incomplete_multipart_upload_days = local.application_data.accounts[local.environment].rman_s3_lifecycle_days_abort_incomplete_multipart_upload_days
    }
  ]

  tags = merge(local.tags,
    { Name = lower(format("s3-%s-%s-dbbackup", local.application_name, local.environment)) }
  )
}

resource "aws_s3_bucket_notification" "dbbackup_bucket_notification" {
  bucket      = module.s3-bucket-dbbackup.bucket.id
  eventbridge = true
  topic {
    topic_arn     = aws_sns_topic.s3_topic.arn
    events        = ["s3:ObjectCreated:*"]
    filter_suffix = ".log"
  }
}

#For shared bucket lifecycle rule is not needed as it host lambda application source code
resource "aws_s3_bucket" "ccms_ebs_shared" {
  bucket = "${local.application_name}-${local.environment}-shared"

  tags = merge(local.tags,
    {
      Name = "${local.application_name}-${local.environment}-shared"
    }
  )
}

resource "aws_s3_object" "folder" {
  bucket = aws_s3_bucket.ccms_ebs_shared.bucket
  for_each = {
    for index, name in local.lambda_folder_name :
    name => index == 0 ? "${name}/" : "lambda_delivery/${name}/"
  }

  key = each.value
}

resource "aws_s3_bucket_public_access_block" "ccms_ebs_shared" {
  bucket                  = aws_s3_bucket.ccms_ebs_shared.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_versioning" "ccms_ebs_shared" {
  bucket = aws_s3_bucket.ccms_ebs_shared.id

  versioning_configuration {
    status = "Enabled"
  }
}

data "aws_iam_policy_document" "shared_bucket_secure_transport" {
  statement {
    sid    = "DenyInsecureTransport"
    effect = "Deny"
    principals {
      type        = "*"
      identifiers = ["*"]
    }
    actions = ["s3:*"]
    resources = [
      aws_s3_bucket.ccms_ebs_shared.arn,
      "${aws_s3_bucket.ccms_ebs_shared.arn}/*",
    ]
    condition {
      test     = "Bool"
      variable = "aws:SecureTransport"
      values   = ["false"]
    }
  }
}

resource "aws_s3_bucket_policy" "shared_bucket_secure_transport" {
  bucket = aws_s3_bucket.ccms_ebs_shared.id
  policy = data.aws_iam_policy_document.shared_bucket_secure_transport.json
}

# S3 Bucket for Payment Load
resource "aws_s3_bucket" "lambda_payment_load" {
  bucket = "${local.application_name}-${local.environment}-payment-load"

  tags = merge(local.tags,
    {
      Name = "${local.application_name}-${local.environment}-payment-load"
    }
  )
}

resource "aws_s3_bucket_public_access_block" "lambda_payment_load" {
  bucket                  = aws_s3_bucket.lambda_payment_load.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_versioning" "lambda_payment_load" {
  bucket = aws_s3_bucket.lambda_payment_load.id

  versioning_configuration {
    status = "Enabled"
  }
}

# Lifecycle configuration: expire current objects and noncurrent versions after 30 days
resource "aws_s3_bucket_lifecycle_configuration" "lambda_payment_load_lifecycle" {
  bucket = aws_s3_bucket.lambda_payment_load.id
  # One lifecycle rule per prefix
  rule {
    id     = "expire-${aws_s3_bucket.lambda_payment_load.id}-${local.application_data.accounts[local.environment].s3_lifecycle_days_expiration_current}d"
    status = "Enabled"

    filter {
      prefix = ""
    }

    expiration {
      days = local.application_data.accounts[local.environment].s3_lifecycle_days_expiration_current
    }

    noncurrent_version_transition {
      noncurrent_days = local.application_data.accounts[local.environment].s3_lifecycle_days_transition_noncurrent_standard
      storage_class   = "STANDARD_IA"
    }

    noncurrent_version_transition {
      noncurrent_days = local.application_data.accounts[local.environment].s3_lifecycle_days_transition_noncurrent_glacier
      storage_class   = "GLACIER"
    }

    noncurrent_version_expiration {
      noncurrent_days = local.application_data.accounts[local.environment].s3_lifecycle_days_expiration_noncurrent
    }

    abort_incomplete_multipart_upload {
      days_after_initiation = local.application_data.accounts[local.environment].s3_lifecycle_days_abort_incomplete_multipart_upload_days
    }
  }
}

data "aws_iam_policy_document" "payment_load_bucket_secure_transport" {
  statement {
    sid    = "DenyInsecureTransport"
    effect = "Deny"
    principals {
      type        = "*"
      identifiers = ["*"]
    }
    actions = ["s3:*"]
    resources = [
      aws_s3_bucket.lambda_payment_load.arn,
      "${aws_s3_bucket.lambda_payment_load.arn}/*",
    ]
    condition {
      test     = "Bool"
      variable = "aws:SecureTransport"
      values   = ["false"]
    }
  }
}

resource "aws_s3_bucket_policy" "payment_load_bucket_secure_transport" {
  bucket = aws_s3_bucket.lambda_payment_load.id
  policy = data.aws_iam_policy_document.payment_load_bucket_secure_transport.json
}

resource "aws_s3_bucket_object_lock_configuration" "dbbackup" {
  count  = local.is-test ? 1 : 0
  bucket = module.s3-bucket-dbbackup.bucket.id

  rule {
    default_retention {
      mode = "COMPLIANCE"
      days = local.application_data.accounts[local.environment].rman_s3_lifecycle_days_expiration_current
    }
  }
}

# ---------------------------------------------
# MOVED blocks
# ---------------------------------------------

moved {
  from = module.s3-bucket-dbbackup.aws_s3_bucket_logging.default["ccms-ebs-development-logging"]
  to   = module.s3-bucket-dbbackup.aws_s3_bucket_logging.default_single_name["ccms-ebs-development-logging"]
}

moved {
  from = module.s3-bucket-logging.aws_s3_bucket_logging.default["ccms-ebs-development-logging"]
  to   = module.s3-bucket-logging.aws_s3_bucket_logging.default_single_name["ccms-ebs-development-logging"]
}

moved {
  from = module.s3-bucket-dbbackup.aws_s3_bucket_logging.default["ccms-ebs-test-logging"]
  to   = module.s3-bucket-dbbackup.aws_s3_bucket_logging.default_single_name["ccms-ebs-test-logging"]
}

moved {
  from = module.s3-bucket-logging.aws_s3_bucket_logging.default["ccms-ebs-test-logging"]
  to   = module.s3-bucket-logging.aws_s3_bucket_logging.default_single_name["ccms-ebs-test-logging"]
}

moved {
  from = module.s3-bucket-dbbackup.aws_s3_bucket_logging.default["ccms-ebs-preproduction-logging"]
  to   = module.s3-bucket-dbbackup.aws_s3_bucket_logging.default_single_name["ccms-ebs-preproduction-logging"]
}

moved {
  from = module.s3-bucket-logging.aws_s3_bucket_logging.default["ccms-ebs-preproduction-logging"]
  to   = module.s3-bucket-logging.aws_s3_bucket_logging.default_single_name["ccms-ebs-preproduction-logging"]
}

moved {
  from = module.s3-bucket-dbbackup.aws_s3_bucket_logging.default["ccms-ebs-production-logging"]
  to   = module.s3-bucket-dbbackup.aws_s3_bucket_logging.default_single_name["ccms-ebs-production-logging"]
}

moved {
  from = module.s3-bucket-logging.aws_s3_bucket_logging.default["ccms-ebs-production-logging"]
  to   = module.s3-bucket-logging.aws_s3_bucket_logging.default_single_name["ccms-ebs-production-logging"]
}
