resource "aws_s3_bucket" "contract_management" {
  for_each = local.contract_bucket_names

  bucket        = each.value
  force_destroy = false

  tags = local.tags

  lifecycle {
    precondition {
      condition = (
        data.aws_caller_identity.current.account_id ==
        local.environment_management.account_ids[terraform.workspace]
      )
      error_message = "The AWS deployment account must match the selected Terraform workspace."
    }
  }
}

resource "aws_s3_bucket_public_access_block" "contract_management" {
  for_each = local.contract_bucket_names

  bucket = aws_s3_bucket.contract_management[each.key].id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_ownership_controls" "contract_management" {
  for_each = local.contract_bucket_names

  bucket = aws_s3_bucket.contract_management[each.key].id

  rule {
    object_ownership = "BucketOwnerEnforced"
  }
}

resource "aws_s3_bucket_versioning" "contract_management" {
  for_each = local.contract_bucket_names

  bucket = aws_s3_bucket.contract_management[each.key].id

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "contract_management" {
  for_each = local.contract_bucket_names

  bucket = aws_s3_bucket.contract_management[each.key].id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = each.key == "contracts" ? "aws:kms" : "AES256"

      kms_master_key_id = each.key == "contracts" ? (
        aws_kms_key.contract_management["contracts"].arn
      ) : null
    }

    bucket_key_enabled = each.key == "contracts"
  }
}

resource "aws_s3_bucket_lifecycle_configuration" "contract_management" {
  for_each = local.contract_bucket_names

  bucket = aws_s3_bucket.contract_management[each.key].id

  rule {
    id     = "abort-incomplete-multipart-uploads"
    status = "Enabled"

    filter {}

    abort_incomplete_multipart_upload {
      days_after_initiation = 7
    }
  }

  depends_on = [
    aws_s3_bucket_versioning.contract_management,
  ]
}

data "aws_iam_policy_document" "contract_bucket" {
  for_each = local.contract_bucket_names

  statement {
    sid    = "DenyInsecureTransport"
    effect = "Deny"

    principals {
      type        = "*"
      identifiers = ["*"]
    }

    actions = ["s3:*"]

    resources = [
      aws_s3_bucket.contract_management[each.key].arn,
      "${aws_s3_bucket.contract_management[each.key].arn}/*",
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
      sid    = "AllowContractBucketAccessLogs"
      effect = "Allow"

      principals {
        type        = "Service"
        identifiers = ["logging.s3.amazonaws.com"]
      }

      actions = ["s3:PutObject"]

      resources = [
        "${aws_s3_bucket.contract_management["access_logs"].arn}/contracts/*",
      ]

      condition {
        test     = "ArnEquals"
        variable = "aws:SourceArn"
        values = [
          aws_s3_bucket.contract_management["contracts"].arn,
        ]
      }

      condition {
        test     = "StringEquals"
        variable = "aws:SourceAccount"
        values   = [data.aws_caller_identity.current.account_id]
      }
    }
  }

  dynamic "statement" {
    for_each = each.key == "contracts" ? [1] : []

    content {
      sid    = "DenyExplicitNonKMSEncryption"
      effect = "Deny"

      principals {
        type        = "*"
        identifiers = ["*"]
      }

      actions = ["s3:PutObject"]

      resources = [
        "${aws_s3_bucket.contract_management["contracts"].arn}/*",
      ]

      condition {
        test     = "Null"
        variable = "s3:x-amz-server-side-encryption"
        values   = ["false"]
      }

      condition {
        test     = "StringNotEquals"
        variable = "s3:x-amz-server-side-encryption"
        values   = ["aws:kms"]
      }
    }
  }

  dynamic "statement" {
    for_each = each.key == "contracts" ? [1] : []

    content {
      sid    = "DenyExplicitDifferentKMSKey"
      effect = "Deny"

      principals {
        type        = "*"
        identifiers = ["*"]
      }

      actions = ["s3:PutObject"]

      resources = [
        "${aws_s3_bucket.contract_management["contracts"].arn}/*",
      ]

      condition {
        test     = "Null"
        variable = "s3:x-amz-server-side-encryption-aws-kms-key-id"
        values   = ["false"]
      }

      condition {
        test     = "StringNotEquals"
        variable = "s3:x-amz-server-side-encryption-aws-kms-key-id"
        values = [
          aws_kms_key.contract_management["contracts"].arn,
        ]
      }
    }
  }

  dynamic "statement" {
    for_each = each.key == "contracts" ? [1] : []

    content {
      sid    = "DenyCustomerProvidedEncryptionKeys"
      effect = "Deny"

      principals {
        type        = "*"
        identifiers = ["*"]
      }

      actions = ["s3:PutObject"]

      resources = [
        "${aws_s3_bucket.contract_management["contracts"].arn}/*",
      ]

      condition {
        test     = "Null"
        variable = "s3:x-amz-server-side-encryption-customer-algorithm"
        values   = ["false"]
      }
    }
  }
}

resource "aws_s3_bucket_policy" "contract_management" {
  for_each = local.contract_bucket_names

  bucket = aws_s3_bucket.contract_management[each.key].id
  policy = data.aws_iam_policy_document.contract_bucket[each.key].json

  depends_on = [
    aws_s3_bucket_public_access_block.contract_management,
    aws_s3_bucket_ownership_controls.contract_management,
  ]
}

resource "aws_s3_bucket_logging" "contracts" {
  count = local.contract_management_enabled ? 1 : 0

  bucket        = aws_s3_bucket.contract_management["contracts"].id
  target_bucket = aws_s3_bucket.contract_management["access_logs"].id
  target_prefix = "contracts/"

  depends_on = [
    aws_s3_bucket_policy.contract_management,
    aws_s3_bucket_server_side_encryption_configuration.contract_management,
  ]
}
