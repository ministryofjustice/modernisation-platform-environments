locals {
  ingestion_artifacts_enabled = local.is-development

  artifact_bucket_names = local.ingestion_artifacts_enabled ? {
    packages    = "${local.application_name}-${local.environment}-artifacts-${data.aws_caller_identity.current.account_id}"
    access_logs = "${local.application_name}-${local.environment}-artifact-logs-${data.aws_caller_identity.current.account_id}"
  } : {}
}

data "aws_partition" "ingestion_artifacts" {}

data "aws_iam_policy_document" "artifact_key" {
  count = local.ingestion_artifacts_enabled ? 1 : 0

  statement {
    sid    = "EnableAccountIAMPermissions"
    effect = "Allow"

    principals {
      type = "AWS"
      identifiers = [
        "arn:${data.aws_partition.ingestion_artifacts.partition}:iam::${data.aws_caller_identity.current.account_id}:root"
      ]
    }

    actions   = ["kms:*"]
    resources = ["*"]
  }
}

resource "aws_kms_key" "artifacts" {
  count = local.ingestion_artifacts_enabled ? 1 : 0

  description             = "Encryption key for shared ingestion deployment artifacts"
  enable_key_rotation     = true
  deletion_window_in_days = 30
  policy                  = data.aws_iam_policy_document.artifact_key[0].json

  tags = local.tags

  lifecycle {
    prevent_destroy = true
  }
}

resource "aws_kms_alias" "artifacts" {
  count = local.ingestion_artifacts_enabled ? 1 : 0

  name          = "alias/${local.application_name}-${local.environment}-ingestion-artifacts"
  target_key_id = aws_kms_key.artifacts[0].key_id
}

resource "aws_s3_bucket" "artifacts" {
  for_each = local.artifact_bucket_names

  bucket        = each.value
  force_destroy = false

  tags = merge(local.tags, {
    Name    = each.value
    Purpose = each.key == "packages" ? "Ingestion deployment artifacts" : "Ingestion artifact access logs"
  })

  lifecycle {
    prevent_destroy = true
  }
}

resource "aws_s3_bucket_public_access_block" "artifacts" {
  for_each = local.artifact_bucket_names

  bucket = aws_s3_bucket.artifacts[each.key].id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_ownership_controls" "artifacts" {
  for_each = local.artifact_bucket_names

  bucket = aws_s3_bucket.artifacts[each.key].id

  rule {
    object_ownership = "BucketOwnerEnforced"
  }
}

resource "aws_s3_bucket_versioning" "artifacts" {
  for_each = local.artifact_bucket_names

  bucket = aws_s3_bucket.artifacts[each.key].id

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "artifacts" {
  for_each = local.artifact_bucket_names

  bucket = aws_s3_bucket.artifacts[each.key].id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = each.key == "packages" ? "aws:kms" : "AES256"

      kms_master_key_id = each.key == "packages" ? (
        aws_kms_key.artifacts[0].arn
      ) : null
    }

    bucket_key_enabled = each.key == "packages"
  }
}

data "aws_iam_policy_document" "artifact_bucket" {
  for_each = local.artifact_bucket_names

  statement {
    sid    = "DenyInsecureTransport"
    effect = "Deny"

    principals {
      type        = "*"
      identifiers = ["*"]
    }

    actions = ["s3:*"]

    resources = [
      aws_s3_bucket.artifacts[each.key].arn,
      "${aws_s3_bucket.artifacts[each.key].arn}/*",
    ]

    condition {
      test     = "Bool"
      variable = "aws:SecureTransport"
      values   = ["false"]
    }
  }

  dynamic "statement" {
    for_each = each.key == "access_logs" ? [1] : []

    content {
      sid    = "AllowArtifactAccessLogDelivery"
      effect = "Allow"

      principals {
        type        = "Service"
        identifiers = ["logging.s3.amazonaws.com"]
      }

      actions = ["s3:PutObject"]

      resources = [
        "${aws_s3_bucket.artifacts["access_logs"].arn}/artifacts/*"
      ]

      condition {
        test     = "ArnEquals"
        variable = "aws:SourceArn"
        values   = [aws_s3_bucket.artifacts["packages"].arn]
      }

      condition {
        test     = "StringEquals"
        variable = "aws:SourceAccount"
        values   = [data.aws_caller_identity.current.account_id]
      }
    }
  }
}

resource "aws_s3_bucket_policy" "artifacts" {
  for_each = local.artifact_bucket_names

  bucket = aws_s3_bucket.artifacts[each.key].id
  policy = data.aws_iam_policy_document.artifact_bucket[each.key].json

  depends_on = [
    aws_s3_bucket_public_access_block.artifacts,
  ]
}

resource "aws_s3_bucket_logging" "artifacts" {
  count = local.ingestion_artifacts_enabled ? 1 : 0

  bucket        = aws_s3_bucket.artifacts["packages"].id
  target_bucket = aws_s3_bucket.artifacts["access_logs"].id
  target_prefix = "artifacts/"

  depends_on = [
    aws_s3_bucket_policy.artifacts,
    aws_s3_bucket_ownership_controls.artifacts,
    aws_s3_bucket_server_side_encryption_configuration.artifacts,
  ]
}
