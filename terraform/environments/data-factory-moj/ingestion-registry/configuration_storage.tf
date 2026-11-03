locals {
  configuration_bucket_names = local.ingestion_registry_enabled ? {
    documents   = "${local.application_name}-${local.environment}-ingestion-config-${data.aws_caller_identity.current.account_id}"
    access_logs = "${local.application_name}-${local.environment}-ingestion-config-logs-${data.aws_caller_identity.current.account_id}"
  } : {}
}

resource "aws_kms_key" "ingestion_configuration" {
  count = local.ingestion_registry_enabled ? 1 : 0

  description             = "Encryption key for published ingestion configuration and deployment manifests"
  enable_key_rotation     = true
  deletion_window_in_days = 30

  policy = data.aws_iam_policy_document.ingestion_registry_kms[0].json

  tags = local.tags

  lifecycle {
    prevent_destroy = true
  }
}

resource "aws_kms_alias" "ingestion_configuration" {
  count = local.ingestion_registry_enabled ? 1 : 0

  name = "alias/${local.application_name}-${local.environment}-ingestion-config"

  target_key_id = aws_kms_key.ingestion_configuration[0].key_id
}

resource "aws_s3_bucket" "ingestion_configuration" {
  for_each = local.configuration_bucket_names

  bucket        = each.value
  force_destroy = false

  tags = local.tags

  lifecycle {
    prevent_destroy = true
  }
}

resource "aws_s3_bucket_public_access_block" "ingestion_configuration" {
  for_each = local.configuration_bucket_names

  bucket = aws_s3_bucket.ingestion_configuration[each.key].id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_ownership_controls" "ingestion_configuration" {
  for_each = local.configuration_bucket_names

  bucket = aws_s3_bucket.ingestion_configuration[each.key].id

  rule {
    object_ownership = "BucketOwnerEnforced"
  }
}

resource "aws_s3_bucket_versioning" "ingestion_configuration" {
  for_each = local.configuration_bucket_names

  bucket = aws_s3_bucket.ingestion_configuration[each.key].id

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "ingestion_configuration" {
  for_each = local.configuration_bucket_names

  bucket = aws_s3_bucket.ingestion_configuration[each.key].id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = each.key == "documents" ? "aws:kms" : "AES256"

      kms_master_key_id = each.key == "documents" ? (
        aws_kms_key.ingestion_configuration[0].arn
      ) : null
    }

    bucket_key_enabled = each.key == "documents"
  }
}

resource "aws_s3_bucket_lifecycle_configuration" "ingestion_configuration" {
  for_each = local.configuration_bucket_names

  bucket = aws_s3_bucket.ingestion_configuration[each.key].id

  rule {
    id     = "abort-incomplete-multipart-uploads"
    status = "Enabled"

    filter {}

    abort_incomplete_multipart_upload {
      days_after_initiation = 7
    }
  }

  depends_on = [
    aws_s3_bucket_versioning.ingestion_configuration,
  ]
}

data "aws_iam_policy_document" "ingestion_configuration_bucket" {
  for_each = local.configuration_bucket_names

  statement {
    sid    = "DenyInsecureTransport"
    effect = "Deny"

    principals {
      type        = "*"
      identifiers = ["*"]
    }

    actions = ["s3:*"]

    resources = [
      aws_s3_bucket.ingestion_configuration[each.key].arn,
      "${aws_s3_bucket.ingestion_configuration[each.key].arn}/*",
    ]

    condition {
      test     = "Bool"
      variable = "aws:SecureTransport"
      values   = ["false"]
    }
  }

  dynamic "statement" {
    for_each = each.key == "access_logs" ? [true] : []

    content {
      sid    = "AllowConfigurationAccessLogs"
      effect = "Allow"

      principals {
        type        = "Service"
        identifiers = ["logging.s3.amazonaws.com"]
      }

      actions = ["s3:PutObject"]

      resources = [
        "${aws_s3_bucket.ingestion_configuration["access_logs"].arn}/configuration/*",
      ]

      condition {
        test     = "StringEquals"
        variable = "aws:SourceAccount"
        values   = [data.aws_caller_identity.current.account_id]
      }

      condition {
        test     = "ArnEquals"
        variable = "aws:SourceArn"
        values = [
          aws_s3_bucket.ingestion_configuration["documents"].arn,
        ]
      }
    }
  }
}

resource "aws_s3_bucket_policy" "ingestion_configuration" {
  for_each = local.configuration_bucket_names

  bucket = aws_s3_bucket.ingestion_configuration[each.key].id
  policy = data.aws_iam_policy_document.ingestion_configuration_bucket[each.key].json

  depends_on = [
    aws_s3_bucket_public_access_block.ingestion_configuration,
  ]
}

resource "aws_s3_bucket_logging" "ingestion_configuration" {
  count = local.ingestion_registry_enabled ? 1 : 0

  bucket = aws_s3_bucket.ingestion_configuration["documents"].id

  target_bucket = aws_s3_bucket.ingestion_configuration["access_logs"].id
  target_prefix = "configuration/"

  depends_on = [
    aws_s3_bucket_policy.ingestion_configuration,
    aws_s3_bucket_ownership_controls.ingestion_configuration,
    aws_s3_bucket_server_side_encryption_configuration.ingestion_configuration,
  ]
}
