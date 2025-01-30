module "s3_staging" {
  source = "../.."
  providers = {
    aws.bucket-replication = aws.bucket-replication
  }
}


# AWS S3 Bucket (Call Centre Staging)
resource "aws_s3_bucket" "default" {
  bucket = var.call_centre_staging_aws_s3_bucket
}

# Event Notifications for S3 buckets
resource "aws_s3_bucket_notification" "default" {
  count  = var.notification_enabled == true ? 1 : 0
  bucket = aws_s3_bucket.default.id

  topic {
    topic_arn = var.notification_sns_arn
    events    = var.notification_events
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "default" {
  bucket = aws_s3_bucket.default.id
  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm     = var.sse_algorithm
      kms_master_key_id = (var.custom_kms_key != "") ? var.custom_kms_key : ""
    }
  }
}

# Enable Versioning on S3 Buckets
resource "aws_s3_bucket_versioning" "default" {
  bucket = aws_s3_bucket.default.id
  versioning_configuration {
    status = (var.versioning_enabled != true) ? "Suspended" : "Enabled"
  }
}

# Configure bucket lifecycle rules
resource "aws_s3_bucket_lifecycle_configuration" "default" {
  #checkov:skip=CKV_AWS_300: "Ensure S3 lifecycle configuration sets period for aborting failed uploads"
  bucket = aws_s3_bucket.default.id

  dynamic "rule" {
    for_each = try(jsondecode(var.lifecycle_rule), var.lifecycle_rule)

    content {
      id = lookup(rule.value, "id", null)
      filter {
        prefix = lookup(rule.value, "prefix", null)
      }
      status = lookup(rule.value, "enabled", null)

      abort_incomplete_multipart_upload {
        days_after_initiation = lookup(rule.value, "abort_incomplete_multipart_upload_days", "7")
      }

      # Max 1 block - expiration
      dynamic "expiration" {
        for_each = length(keys(lookup(rule.value, "expiration", {}))) == 0 ? [] : [lookup(rule.value, "expiration", {})]

        content {
          date                         = lookup(expiration.value, "date", null)
          days                         = lookup(expiration.value, "days", null)
          expired_object_delete_marker = lookup(expiration.value, "expired_object_delete_marker", null)
        }
      }

      # Several blocks - transition
      dynamic "transition" {
        for_each = lookup(rule.value, "transition", [])

        content {
          date          = lookup(transition.value, "date", null)
          days          = lookup(transition.value, "days", null)
          storage_class = transition.value.storage_class
        }
      }

      # Max 1 block - noncurrent_version_expiration
      dynamic "noncurrent_version_expiration" {
        for_each = length(keys(lookup(rule.value, "noncurrent_version_expiration", {}))) == 0 ? [] : [
          lookup(rule.value, "noncurrent_version_expiration", {})
        ]

        content {
          noncurrent_days = lookup(noncurrent_version_expiration.value, "days", null)
        }
      }

      # Several blocks - noncurrent_version_transition
      dynamic "noncurrent_version_transition" {
        for_each = lookup(rule.value, "noncurrent_version_transition", [])

        content {
          noncurrent_days = lookup(noncurrent_version_transition.value, "days", null)
          storage_class   = noncurrent_version_transition.value.storage_class
        }
      }
    }
  }
}

# AWS S3 Bucket Logging
resource "aws_s3_bucket_logging" "default" {
  count = var.log_buckets != null ? 1 : 0

  bucket        = aws_s3_bucket.default.id
  target_bucket = var.log_bucket_name
  target_prefix = var.log_prefix

  dynamic "target_object_key_format" {
    for_each = (var.log_partition_date_source != "None") ? [1] : []
    content {
      partitioned_prefix {
        partition_date_source = var.log_partition_date_source
      }
    }
  }
}

# Block public access policies for this bucket
resource "aws_s3_bucket_public_access_block" "default" {
  bucket                  = aws_s3_bucket.default.bucket
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# S3 bucket replication: role
resource "aws_iam_role" "replication" {
  provider           = aws.bucket-replication
  count              = var.replication_enabled ? 1 : 0
  name               = "AWSS3BucketReplication${var.suffix_name}"
  assume_role_policy = data.aws_iam_policy_document.s3-assume-role-policy.json
  # tags               = var.tags
}

# S3 bucket replication: assume role policy
data "aws_iam_policy_document" "s3-assume-role-policy" {
  version = var.json_encode_decode_version
  statement {
    effect  = var.moj_aws_iam_policy_document_statement_effect
    actions = var.moj_aws_iam_policy_document_statement_actions

    principals {
      type        = var.moj_aws_iam_policy_document_principals_type
      identifiers = var.moj_aws_iam_policy_document_principals_identifiers
    }
  }
}

# AWS S3 Bucket cross-region replication
resource "aws_s3_bucket_replication_configuration" "default" {
  for_each = var.replication_enabled ? toset(["run"]) : []
  bucket   = aws_s3_bucket.default.id
  role     = aws_iam_role.replication[0].arn
  rule {
    id       = var.moj_aws_s3_bucket_replication_configuration_rule_id
    status   = var.replication_enabled ? "Enabled" : "Disabled"
    priority = 0

    destination {
      # bucket        = var.replication_enabled ? aws_s3_bucket.replication[0].arn : aws_s3_bucket.replication[0].arn
      bucket        = aws_s3_bucket.default.arn
      storage_class = var.moj_aws_s3_bucket_replication_configuration_rule_destination_storage_class
      encryption_configuration {
        replica_kms_key_id = (var.custom_replication_kms_key != "") ? var.custom_replication_kms_key : "arn:aws:kms:${var.replication_region}:${data.aws_caller_identity.current.account_id}:alias/aws/s3"
      }
    }

    source_selection_criteria {
      sse_kms_encrypted_objects {
        status = (var.replication_enabled != false) ? "Enabled" : "Disabled"
      }
    }
  }
  depends_on = [
    aws_s3_bucket_versioning.default
  ]
}

# AWS S3 Bucket Policy (Call Centre Staging)
resource "aws_s3_bucket_policy" "default" {
  bucket = var.call_centre_staging_aws_s3_bucket
  policy = jsonencode({
    Version = var.json_encode_decode_version,
    Statement = [
      {
        Sid    = var.moj_aws_s3_bucket_policy_statement_sid,
        Effect = var.moj_aws_s3_bucket_policy_statement_effect,
        Principal = {
          Service : var.moj_aws_s3_bucket_policy_statement_principal_service
        },
        Action   = var.moj_aws_s3_bucket_policy_statement_action,
        Resource = "arn:aws:s3:::${aws_s3_bucket.default.id}/*"
      },
      {
        Sid    = var.bt_genesys_aws_s3_bucket_policy_statement_sid,
        Effect = var.bt_genesys_aws_s3_bucket_policy_statement_effect,
        Principal = {
          AWS = var.bt_genesys_aws_s3_bucket_policy_statement_principal_aws
        },
        Action   = var.bt_genesys_aws_s3_bucket_policy_statement_action,
        Resource = "arn:aws:s3:::${aws_s3_bucket.default.id}/*"
      }
    ]
  })
}

# AWS GuardDuty Detector (Call Centre Staging)
resource "aws_guardduty_detector" "default" {
  enable = var.aws_guardduty_detector_enable
}

# AWS GuardDuty Publishing Destination (Call Centre Staging)
resource "aws_guardduty_publishing_destination" "default" {
  detector_id     = aws_guardduty_detector.default.id
  destination_arn = aws_s3_bucket.default.arn
  kms_key_arn     = aws_kms_key.s3.arn
  depends_on = [
    aws_s3_bucket.default,
    aws_s3_bucket_policy.default
  ]
}

# AWS KMS Key (Call Centre Staging)
resource "aws_kms_key" "s3" {
  description = var.aws_kms_key_s3_description
  key_usage   = var.aws_kms_key_s3_key_usage
  policy = jsonencode({
    Version = var.json_encode_decode_version,
    Statement = [
      {
        Sid    = var.aws_kms_key_s3_policy_statement_sid,
        Effect = var.aws_kms_key_s3_policy_statement_effect,
        Principal = {
          Service = var.aws_kms_key_s3_policy_statement_principal_service
        },
        Action   = var.aws_kms_key_s3_policy_statement_action,
        Resource = var.aws_kms_key_s3_policy_statement_resource
      }
    ]
  })
}

data "aws_caller_identity" "current" {}
