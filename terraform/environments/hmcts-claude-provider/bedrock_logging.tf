locals {
  # Invocation logging is per region and only captures requests made to that region's endpoint.
  # Claude Code is documented to use eu-west-1, but eu-west-2 is the account default and the
  # Bedrock policy admits inference profiles in any region, so traffic arrives at both.
  #
  # Bedrock only accepts a log destination in the same region as the configuration, so each region
  # needs its own bucket, key and log group. eu-west-1 keeps its original unsuffixed bucket name;
  # renaming it would replace the bucket and discard the logs already in it.
  bedrock_log_buckets = {
    "eu-west-1" = "hmcts-claude-provider-bedrock-logs-${data.aws_caller_identity.current.account_id}"
    "eu-west-2" = "hmcts-claude-provider-bedrock-logs-${data.aws_caller_identity.current.account_id}-eu-west-2"
  }
  bedrock_logging_regions    = keys(local.bedrock_log_buckets)
  bedrock_log_retention_days = 90
}

resource "aws_s3_bucket" "bedrock_logs" {
  #checkov:skip=CKV_AWS_18: "Access logging not required for a log bucket"
  #checkov:skip=CKV_AWS_144: "Cross-region replication not required"
  #checkov:skip=CKV2_AWS_62: "Event notifications not required"
  for_each = local.bedrock_log_buckets
  region   = each.key
  bucket   = each.value
}

resource "aws_s3_bucket_public_access_block" "bedrock_logs" {
  for_each                = aws_s3_bucket.bedrock_logs
  region                  = each.key
  bucket                  = each.value.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_versioning" "bedrock_logs" {
  for_each = aws_s3_bucket.bedrock_logs
  region   = each.key
  bucket   = each.value.id

  versioning_configuration {
    status = "Enabled"
  }
}

data "aws_iam_policy_document" "bedrock_logs_kms" {
  #checkov:skip=CKV_AWS_109: "Resource * in a key policy means the key the policy is attached to"
  #checkov:skip=CKV_AWS_111: "Resource * in a key policy means the key the policy is attached to"
  #checkov:skip=CKV_AWS_356: "Resource * in a key policy means the key the policy is attached to"
  for_each = local.bedrock_log_buckets

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
      identifiers = ["logs.${each.key}.amazonaws.com"]
    }

    condition {
      test     = "ArnLike"
      variable = "kms:EncryptionContext:aws:logs:arn"
      values   = ["arn:aws:logs:${each.key}:${data.aws_caller_identity.current.account_id}:log-group:*"]
    }
  }
}

resource "aws_kms_key" "bedrock_logs" {
  for_each                = local.bedrock_log_buckets
  region                  = each.key
  description             = "Encrypts Bedrock model invocation logs"
  enable_key_rotation     = true
  deletion_window_in_days = 30
  policy                  = data.aws_iam_policy_document.bedrock_logs_kms[each.key].json
}

resource "aws_kms_alias" "bedrock_logs" {
  for_each      = aws_kms_key.bedrock_logs
  region        = each.key
  name          = "alias/bedrock-invocation-logs"
  target_key_id = each.value.key_id
}

resource "aws_s3_bucket_server_side_encryption_configuration" "bedrock_logs" {
  for_each = aws_s3_bucket.bedrock_logs
  region   = each.key
  bucket   = each.value.id

  rule {
    bucket_key_enabled = true

    apply_server_side_encryption_by_default {
      sse_algorithm     = "aws:kms"
      kms_master_key_id = aws_kms_key.bedrock_logs[each.key].arn
    }
  }
}

resource "aws_s3_bucket_lifecycle_configuration" "bedrock_logs" {
  for_each = aws_s3_bucket.bedrock_logs
  region   = each.key
  bucket   = each.value.id

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
  for_each = aws_s3_bucket.bedrock_logs

  statement {
    sid       = "AllowBedrockDelivery"
    effect    = "Allow"
    actions   = ["s3:PutObject"]
    resources = ["${each.value.arn}/*"]

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
      values   = ["arn:aws:bedrock:${each.key}:${data.aws_caller_identity.current.account_id}:*"]
    }
  }

  statement {
    sid       = "DenyInsecureTransport"
    effect    = "Deny"
    actions   = ["s3:*"]
    resources = [each.value.arn, "${each.value.arn}/*"]

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
  for_each = aws_s3_bucket.bedrock_logs
  region   = each.key
  bucket   = each.value.id
  policy   = data.aws_iam_policy_document.bedrock_logs[each.key].json
}

resource "aws_cloudwatch_log_group" "bedrock_logs" {
  #checkov:skip=CKV_AWS_338: "Records contain prompt and source code content, retained for 90 days to match the S3 lifecycle"
  for_each          = local.bedrock_log_buckets
  region            = each.key
  name              = "/aws/bedrock/modelinvocations"
  retention_in_days = local.bedrock_log_retention_days
  kms_key_id        = aws_kms_key.bedrock_logs[each.key].arn
}

# One role covers every region: IAM is global, and the policies below name each region explicitly.
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
      values = [
        for region in local.bedrock_logging_regions :
        "arn:aws:bedrock:${region}:${data.aws_caller_identity.current.account_id}:*"
      ]
    }
  }
}

resource "aws_iam_role" "bedrock_logs" {
  name               = "BedrockInvocationLogging"
  assume_role_policy = data.aws_iam_policy_document.bedrock_logs_assume_role.json
}

data "aws_iam_policy_document" "bedrock_logs_delivery" {
  statement {
    actions = ["logs:CreateLogStream", "logs:PutLogEvents"]
    resources = [
      for log_group in aws_cloudwatch_log_group.bedrock_logs :
      "${log_group.arn}:log-stream:aws/bedrock/modelinvocations"
    ]
  }
}

resource "aws_iam_role_policy" "bedrock_logs" {
  name   = "BedrockInvocationLogging"
  role   = aws_iam_role.bedrock_logs.id
  policy = data.aws_iam_policy_document.bedrock_logs_delivery.json
}

resource "aws_bedrock_model_invocation_logging_configuration" "this" {
  for_each = local.bedrock_log_buckets
  region   = each.key

  logging_config {
    embedding_data_delivery_enabled = false
    image_data_delivery_enabled     = false
    video_data_delivery_enabled     = false

    # Request and response bodies are the only sensitive part of a record and almost all of its
    # volume. Token counts, identity and requestMetadata are envelope fields and keep being
    # delivered without them.
    text_data_delivery_enabled = false

    s3_config {
      bucket_name = aws_s3_bucket.bedrock_logs[each.key].id
      key_prefix  = "invocation-logs"
    }

    cloudwatch_config {
      log_group_name = aws_cloudwatch_log_group.bedrock_logs[each.key].name
      role_arn       = aws_iam_role.bedrock_logs.arn

      # Bodies over 100KB are delivered here instead of inline in the log event
      large_data_delivery_s3_config {
        bucket_name = aws_s3_bucket.bedrock_logs[each.key].id
        key_prefix  = "large-data"
      }
    }
  }

  depends_on = [aws_s3_bucket_policy.bedrock_logs]
}

# The eu-west-1 resources predate the move to one set per region. These keep the existing
# infrastructure in place instead of replacing it, and can be removed once applied.
moved {
  from = aws_s3_bucket.bedrock_logs
  to   = aws_s3_bucket.bedrock_logs["eu-west-1"]
}

moved {
  from = aws_s3_bucket_public_access_block.bedrock_logs
  to   = aws_s3_bucket_public_access_block.bedrock_logs["eu-west-1"]
}

moved {
  from = aws_s3_bucket_versioning.bedrock_logs
  to   = aws_s3_bucket_versioning.bedrock_logs["eu-west-1"]
}

moved {
  from = aws_kms_key.bedrock_logs
  to   = aws_kms_key.bedrock_logs["eu-west-1"]
}

moved {
  from = aws_kms_alias.bedrock_logs
  to   = aws_kms_alias.bedrock_logs["eu-west-1"]
}

moved {
  from = aws_s3_bucket_server_side_encryption_configuration.bedrock_logs
  to   = aws_s3_bucket_server_side_encryption_configuration.bedrock_logs["eu-west-1"]
}

moved {
  from = aws_s3_bucket_lifecycle_configuration.bedrock_logs
  to   = aws_s3_bucket_lifecycle_configuration.bedrock_logs["eu-west-1"]
}

moved {
  from = aws_s3_bucket_policy.bedrock_logs
  to   = aws_s3_bucket_policy.bedrock_logs["eu-west-1"]
}

moved {
  from = aws_cloudwatch_log_group.bedrock_logs
  to   = aws_cloudwatch_log_group.bedrock_logs["eu-west-1"]
}

moved {
  from = aws_bedrock_model_invocation_logging_configuration.this
  to   = aws_bedrock_model_invocation_logging_configuration.this["eu-west-1"]
}
