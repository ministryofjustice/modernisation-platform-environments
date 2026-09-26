locals {
  # Invocation logging is per region and only captures requests made to that region's endpoint
  bedrock_logging_region     = "eu-west-1"
  bedrock_log_bucket         = "hmcts-claude-provider-bedrock-logs-${data.aws_caller_identity.current.account_id}"
  bedrock_log_retention_days = 90
}

resource "aws_s3_bucket" "bedrock_logs" {
  #checkov:skip=CKV_AWS_18: "Access logging not required for a log bucket"
  #checkov:skip=CKV_AWS_144: "Cross-region replication not required"
  #checkov:skip=CKV2_AWS_62: "Event notifications not required"
  region = local.bedrock_logging_region
  bucket = local.bedrock_log_bucket
}

resource "aws_s3_bucket_public_access_block" "bedrock_logs" {
  region                  = local.bedrock_logging_region
  bucket                  = aws_s3_bucket.bedrock_logs.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_versioning" "bedrock_logs" {
  region = local.bedrock_logging_region
  bucket = aws_s3_bucket.bedrock_logs.id

  versioning_configuration {
    status = "Enabled"
  }
}

data "aws_iam_policy_document" "bedrock_logs_kms" {
  #checkov:skip=CKV_AWS_109: "Resource * in a key policy means the key the policy is attached to"
  #checkov:skip=CKV_AWS_111: "Resource * in a key policy means the key the policy is attached to"
  #checkov:skip=CKV_AWS_356: "Resource * in a key policy means the key the policy is attached to"
  statement {
    sid       = "AllowAccountAdministration"
    effect    = "Allow"
    actions   = ["kms:*"]
    resources = ["*"]

    principals {
      type        = "AWS"
      identifiers = ["arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"]
    }
  }

  statement {
    sid       = "AllowBedrockDelivery"
    effect    = "Allow"
    actions   = ["kms:GenerateDataKey", "kms:Decrypt"]
    resources = ["*"]

    principals {
      type        = "Service"
      identifiers = ["bedrock.amazonaws.com"]
    }

    condition {
      test     = "StringEquals"
      variable = "aws:SourceAccount"
      values   = [data.aws_caller_identity.current.account_id]
    }
  }

  statement {
    sid    = "AllowCloudWatchLogs"
    effect = "Allow"
    actions = [
      "kms:Encrypt*",
      "kms:Decrypt*",
      "kms:ReEncrypt*",
      "kms:GenerateDataKey*",
      "kms:Describe*",
    ]
    resources = ["*"]

    principals {
      type        = "Service"
      identifiers = ["logs.${local.bedrock_logging_region}.amazonaws.com"]
    }

    condition {
      test     = "ArnLike"
      variable = "kms:EncryptionContext:aws:logs:arn"
      values   = ["arn:aws:logs:${local.bedrock_logging_region}:${data.aws_caller_identity.current.account_id}:log-group:*"]
    }
  }
}

resource "aws_kms_key" "bedrock_logs" {
  region                  = local.bedrock_logging_region
  description             = "Encrypts Bedrock model invocation logs"
  enable_key_rotation     = true
  deletion_window_in_days = 30
  policy                  = data.aws_iam_policy_document.bedrock_logs_kms.json
}

resource "aws_kms_alias" "bedrock_logs" {
  region        = local.bedrock_logging_region
  name          = "alias/bedrock-invocation-logs"
  target_key_id = aws_kms_key.bedrock_logs.key_id
}

resource "aws_s3_bucket_server_side_encryption_configuration" "bedrock_logs" {
  region = local.bedrock_logging_region
  bucket = aws_s3_bucket.bedrock_logs.id

  rule {
    bucket_key_enabled = true

    apply_server_side_encryption_by_default {
      sse_algorithm     = "aws:kms"
      kms_master_key_id = aws_kms_key.bedrock_logs.arn
    }
  }
}

resource "aws_s3_bucket_lifecycle_configuration" "bedrock_logs" {
  region = local.bedrock_logging_region
  bucket = aws_s3_bucket.bedrock_logs.id

  rule {
    id     = "expire-logs"
    status = "Enabled"

    filter {}

    expiration {
      days = local.bedrock_log_retention_days
    }

    noncurrent_version_expiration {
      noncurrent_days = 7
    }

    abort_incomplete_multipart_upload {
      days_after_initiation = 7
    }
  }
}

data "aws_iam_policy_document" "bedrock_logs" {
  statement {
    sid       = "AllowBedrockDelivery"
    effect    = "Allow"
    actions   = ["s3:PutObject"]
    resources = ["${aws_s3_bucket.bedrock_logs.arn}/*"]

    principals {
      type        = "Service"
      identifiers = ["bedrock.amazonaws.com"]
    }

    condition {
      test     = "StringEquals"
      variable = "aws:SourceAccount"
      values   = [data.aws_caller_identity.current.account_id]
    }

    condition {
      test     = "ArnLike"
      variable = "aws:SourceArn"
      values   = ["arn:aws:bedrock:${local.bedrock_logging_region}:${data.aws_caller_identity.current.account_id}:*"]
    }
  }

  statement {
    sid       = "DenyInsecureTransport"
    effect    = "Deny"
    actions   = ["s3:*"]
    resources = [aws_s3_bucket.bedrock_logs.arn, "${aws_s3_bucket.bedrock_logs.arn}/*"]

    principals {
      type        = "*"
      identifiers = ["*"]
    }

    condition {
      test     = "Bool"
      variable = "aws:SecureTransport"
      values   = ["false"]
    }
  }
}

resource "aws_s3_bucket_policy" "bedrock_logs" {
  region = local.bedrock_logging_region
  bucket = aws_s3_bucket.bedrock_logs.id
  policy = data.aws_iam_policy_document.bedrock_logs.json
}

resource "aws_cloudwatch_log_group" "bedrock_logs" {
  #checkov:skip=CKV_AWS_338: "Records contain prompt and source code content, retained for 90 days to match the S3 lifecycle"
  region            = local.bedrock_logging_region
  name              = "/aws/bedrock/modelinvocations"
  retention_in_days = local.bedrock_log_retention_days
  kms_key_id        = aws_kms_key.bedrock_logs.arn
}

data "aws_iam_policy_document" "bedrock_logs_assume_role" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["bedrock.amazonaws.com"]
    }

    condition {
      test     = "StringEquals"
      variable = "aws:SourceAccount"
      values   = [data.aws_caller_identity.current.account_id]
    }

    condition {
      test     = "ArnLike"
      variable = "aws:SourceArn"
      values   = ["arn:aws:bedrock:${local.bedrock_logging_region}:${data.aws_caller_identity.current.account_id}:*"]
    }
  }
}

resource "aws_iam_role" "bedrock_logs" {
  name               = "BedrockInvocationLogging"
  assume_role_policy = data.aws_iam_policy_document.bedrock_logs_assume_role.json
}

data "aws_iam_policy_document" "bedrock_logs_delivery" {
  statement {
    actions   = ["logs:CreateLogStream", "logs:PutLogEvents"]
    resources = ["${aws_cloudwatch_log_group.bedrock_logs.arn}:log-stream:aws/bedrock/modelinvocations"]
  }
}

resource "aws_iam_role_policy" "bedrock_logs" {
  name   = "BedrockInvocationLogging"
  role   = aws_iam_role.bedrock_logs.id
  policy = data.aws_iam_policy_document.bedrock_logs_delivery.json
}

resource "aws_bedrock_model_invocation_logging_configuration" "this" {
  region = local.bedrock_logging_region

  logging_config {
    embedding_data_delivery_enabled = false
    image_data_delivery_enabled     = false
    text_data_delivery_enabled      = true
    video_data_delivery_enabled     = false

    s3_config {
      bucket_name = aws_s3_bucket.bedrock_logs.id
      key_prefix  = "invocation-logs"
    }

    cloudwatch_config {
      log_group_name = aws_cloudwatch_log_group.bedrock_logs.name
      role_arn       = aws_iam_role.bedrock_logs.arn

      # Bodies over 100KB are delivered here instead of inline in the log event
      large_data_delivery_s3_config {
        bucket_name = aws_s3_bucket.bedrock_logs.id
        key_prefix  = "large-data"
      }
    }
  }

  depends_on = [aws_s3_bucket_policy.bedrock_logs]
}
