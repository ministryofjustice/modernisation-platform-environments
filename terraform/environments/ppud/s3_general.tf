##########################################################################################
# General S3 Buckets for Infrastructure, Logs and PPUD files 
##########################################################################################

locals {
  # Cross-account access flags - set to true temporarily when cross-account access is required
  cross_account_access = {
    general_infrastructure_dev  = false
    general_infrastructure_uat  = false
    general_infrastructure_prod = false
  }

  cross_account_principals = {
    general_infrastructure_dev = [
      "arn:aws:iam::${local.environment_management.account_ids["ppud-preproduction"]}:role/ec2-iam-role",
      "arn:aws:iam::${local.environment_management.account_ids["ppud-production"]}:role/ec2-iam-role",
    ]
    general_infrastructure_uat = [
      "arn:aws:iam::${local.environment_management.account_ids["ppud-development"]}:role/ec2-iam-role",
      "arn:aws:iam::${local.environment_management.account_ids["ppud-production"]}:role/ec2-iam-role",
    ]
    general_infrastructure_prod = [
      "arn:aws:iam::${local.environment_management.account_ids["ppud-development"]}:role/ec2-iam-role",
      "arn:aws:iam::${local.environment_management.account_ids["ppud-preproduction"]}:role/ec2-iam-role",
    ]
  }

  s3_general_buckets = {
    for k, v in {
      general_infrastructure_dev = {
        condition                = local.is-development
        bucket_name              = "moj-general-infrastructure-dev"
        log_bucket               = "moj-general-logs-dev"
        log_prefix               = "s3-logs/moj-general-infrastructure-dev/"
        lifecycle_id             = "delete-moj-general-infrastructure-dev"
        ec2_account              = "ppud-development"
        enable_versioning        = true
        enable_logging           = true
        expiration_days          = null
        is_infrastructure_bucket = true
        is_log_bucket            = false
      }
      general_logs_dev = {
        condition                = local.is-development
        bucket_name              = "moj-general-logs-dev"
        log_bucket               = "moj-general-logs-dev" # Self-logging
        log_prefix               = "s3-logs/moj-general-logs-dev/"
        lifecycle_id             = "delete-moj-general-logs-dev"
        ec2_account              = "ppud-development"
        enable_versioning        = false
        enable_logging           = true
        expiration_days          = 120
        is_infrastructure_bucket = false
        is_log_bucket            = true
      }
      general_infrastructure_uat = {
        condition                = local.is-preproduction
        bucket_name              = "moj-general-infrastructure-uat"
        log_bucket               = "moj-general-logs-uat"
        log_prefix               = "s3-logs/moj-general-infrastructure-uat/"
        lifecycle_id             = "delete-moj-general-infrastructure-uat"
        ec2_account              = "ppud-preproduction"
        enable_versioning        = true
        enable_logging           = true
        expiration_days          = null
        is_infrastructure_bucket = true
        is_log_bucket            = false
      }
      general_logs_uat = {
        condition                = local.is-preproduction
        bucket_name              = "moj-general-logs-uat"
        log_bucket               = "moj-general-logs-uat" # Self-logging
        log_prefix               = "s3-logs/moj-general-logs-uat/"
        lifecycle_id             = "delete-moj-general-logs-uat"
        ec2_account              = "ppud-preproduction"
        enable_versioning        = false
        enable_logging           = true
        expiration_days          = 120
        is_infrastructure_bucket = false
        is_log_bucket            = true
      }
      general_infrastructure_prod = {
        condition                = local.is-production
        bucket_name              = "moj-general-infrastructure-prod"
        log_bucket               = "moj-general-logs-prod"
        log_prefix               = "s3-logs/moj-general-infrastructure-prod/"
        lifecycle_id             = "delete-moj-general-infrastructure-prod"
        ec2_account              = "ppud-production"
        enable_versioning        = true
        enable_logging           = true
        expiration_days          = null
        is_infrastructure_bucket = true
        is_log_bucket            = false
      }
      general_logs_prod = {
        condition                = local.is-production
        bucket_name              = "moj-general-logs-prod"
        log_bucket               = "moj-general-logs-prod" # Self-logging
        log_prefix               = "s3-logs/moj-general-logs-prod/"
        lifecycle_id             = "delete-moj-general-logs-prod"
        ec2_account              = "ppud-production"
        enable_versioning        = false
        enable_logging           = true
        expiration_days          = 120
        is_infrastructure_bucket = false
        is_log_bucket            = true
      }
      ppud_files_prod = {
        condition                = local.is-production
        bucket_name              = "moj-ppud-files-prod"
        log_bucket               = "moj-general-logs-prod"
        log_prefix               = "s3-logs/moj-ppud-files-prod/"
        lifecycle_id             = "delete-moj-ppud-files-prod"
        ec2_account              = "ppud-production"
        enable_versioning        = true
        enable_logging           = true
        expiration_days          = null
        is_infrastructure_bucket = false
        is_log_bucket            = false
      }
    } : k => v if v.condition
  }
}

resource "aws_s3_bucket" "s3_general" {
  # checkov:skip=CKV_AWS_145: "S3 bucket is not public facing, does not contain any sensitive information and does not need encryption"
  # checkov:skip=CKV_AWS_144: "PPUD has a UK Sovereignty requirement so cross region replication is prohibited"
  for_each = local.s3_general_buckets
  bucket   = each.value.bucket_name
  tags = merge(local.tags, {
    Name = "${local.application_name}-${each.value.bucket_name}"
  })
}

resource "aws_s3_bucket_versioning" "s3_general" {
  for_each = { for k, v in local.s3_general_buckets : k => v if v.enable_versioning }
  bucket   = aws_s3_bucket.s3_general[each.key].id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_logging" "s3_general" {
  for_each      = { for k, v in local.s3_general_buckets : k => v if v.enable_logging }
  bucket        = aws_s3_bucket.s3_general[each.key].id
  target_bucket = each.value.log_bucket
  target_prefix = each.value.log_prefix
}

resource "aws_s3_bucket_public_access_block" "s3_general" {
  for_each                = local.s3_general_buckets
  bucket                  = aws_s3_bucket.s3_general[each.key].id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_lifecycle_configuration" "s3_general" {
  # checkov:skip=CKV_AWS_300: "S3 bucket has a set period for aborting failed uploads, this is a false positive finding"
  for_each = local.s3_general_buckets
  bucket   = aws_s3_bucket.s3_general[each.key].id
  rule {
    id     = each.value.lifecycle_id
    status = "Enabled"
    filter {
      prefix = ""
    }
    abort_incomplete_multipart_upload {
      days_after_initiation = 3
    }
    dynamic "expiration" {
      for_each = each.value.expiration_days != null ? [1] : []
      content {
        days = each.value.expiration_days
      }
    }
  }
  dynamic "rule" {
    for_each = each.value.is_infrastructure_bucket ? [1] : []
    content {
      id     = "delete-lambda-output-${each.value.bucket_name}"
      status = "Enabled"
      filter {
        prefix = "lambda/output/"
      }
      expiration {
        days = 60
      }
    }
  }
  dynamic "rule" {
    for_each = each.value.is_log_bucket ? [1] : []
    content {
      id     = "transition-to-standard-ia-${each.value.bucket_name}"
      status = "Enabled"
      filter {
        prefix = ""
      }
      transition {
        days          = 30
        storage_class = "STANDARD_IA"
      }
    }
  }
  dynamic "rule" {
    for_each = each.key == "ppud_files_prod" ? [1] : []
    content {
      id     = "transition-ppud-files-to-standard-ia"
      status = "Enabled"
      filter {
        prefix = ""
      }
      noncurrent_version_transition {
        noncurrent_days = 30
        storage_class   = "STANDARD_IA"
      }
      transition {
        days          = 60
        storage_class = "STANDARD_IA"
      }
    }
  }
}

resource "aws_s3_bucket_notification" "s3_general" {
  for_each    = local.s3_general_buckets
  bucket      = aws_s3_bucket.s3_general[each.key].id
  eventbridge = true
  # Uncomment to re-enable SNS notifications
  #topic {
  #  topic_arn = local.is-production ? aws_sns_topic.s3_bucket_notifications_prod[0].arn : (
  #    local.is-preproduction ? aws_sns_topic.s3_bucket_notifications_uat[0].arn :
  #    aws_sns_topic.s3_bucket_notifications_dev[0].arn
  #  )
  #  events        = ["s3:ObjectCreated:*"]
  #  filter_prefix = ""
  #}
}

# Standard S3 Bucket policy for all buckets
# Infrastructure buckets also include CrossAccountEC2Access when local.cross_account_access[key] = true

resource "aws_s3_bucket_policy" "s3_general" {
  for_each = local.s3_general_buckets
  bucket   = aws_s3_bucket.s3_general[each.key].id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = concat(
      [
        {
          Sid       = "RequireSSLRequests"
          Effect    = "Deny"
          Principal = "*"
          Action    = "s3:*"
          Resource = [
            aws_s3_bucket.s3_general[each.key].arn,
            "${aws_s3_bucket.s3_general[each.key].arn}/*"
          ]
          Condition = {
            Bool = { "aws:SecureTransport" = "false" }
          }
        },
        {
          Sid    = "EC2Access"
          Effect = "Allow"
          Action = ["s3:GetBucketAcl", "s3:DeleteObject", "s3:GetObject", "s3:PutObject", "s3:ListBucket"]
          Resource = [
            aws_s3_bucket.s3_general[each.key].arn,
            "${aws_s3_bucket.s3_general[each.key].arn}/*"
          ]
          Principal = {
            AWS = ["arn:aws:iam::${local.environment_management.account_ids[each.value.ec2_account]}:role/ec2-iam-role"]
          }
        },
        {
          Sid    = "LoggingService"
          Effect = "Allow"
          Action = ["s3:PutBucketNotification", "s3:GetBucketNotification", "s3:GetBucketAcl", "s3:DeleteObject", "s3:GetObject", "s3:PutObject", "s3:ListBucket"]
          Resource = [
            aws_s3_bucket.s3_general[each.key].arn,
            "${aws_s3_bucket.s3_general[each.key].arn}/*"
          ]
          Principal = { Service = "logging.s3.amazonaws.com" }
        },
        {
          Sid    = "SNSService"
          Effect = "Allow"
          Action = ["s3:PutBucketNotification", "s3:GetBucketNotification", "s3:GetBucketAcl", "s3:DeleteObject", "s3:GetObject", "s3:PutObject", "s3:ListBucket"]
          Resource = [
            aws_s3_bucket.s3_general[each.key].arn,
            "${aws_s3_bucket.s3_general[each.key].arn}/*"
          ]
          Principal = { Service = "sns.amazonaws.com" }
        }
      ],
      # CrossAccountEC2Access - only added when cross_account_access flag is true for this bucket
      each.value.is_infrastructure_bucket && lookup(local.cross_account_access, each.key, false) ? [
        {
          Sid    = "CrossAccountEC2Access"
          Effect = "Allow"
          Action = ["s3:GetBucketAcl", "s3:DeleteObject", "s3:GetObject", "s3:PutObject", "s3:ListBucket"]
          Resource = [
            aws_s3_bucket.s3_general[each.key].arn,
            "${aws_s3_bucket.s3_general[each.key].arn}/*"
          ]
          Principal = {
            AWS = local.cross_account_principals[each.key]
          }
        }
      ] : []
    )
  })
}
