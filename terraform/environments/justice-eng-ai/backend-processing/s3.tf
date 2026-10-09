data "aws_iam_roles" "account" {}

data "aws_iam_role" "account" {
  for_each = data.aws_iam_roles.account.names

  name = each.value
}

locals {
  ecs_task_roles = {
    for name, role in data.aws_iam_role.account : name => role
    if anytrue([
      for statement in jsondecode(role.assume_role_policy).Statement :
      statement.Effect == "Allow" &&
      contains(flatten([try(statement.Principal.Service, [])]), "ecs-tasks.amazonaws.com") &&
      contains(flatten([statement.Action]), "sts:AssumeRole")
    ])
  }
}

data "aws_iam_policy_document" "staging_bucket_kms" {
  statement {
    sid       = "EnableAccountIAMPermissions"
    effect    = "Allow"
    actions   = ["kms:*"]
    resources = ["*"]

    principals {
      type        = "AWS"
      identifiers = ["arn:${data.aws_partition.current.partition}:iam::${data.aws_caller_identity.current.account_id}:root"]
    }
  }
}

resource "aws_kms_key" "staging_bucket" {
  description             = "Encrypt objects in the staging bucket"
  enable_key_rotation     = true
  deletion_window_in_days = 30
  policy                  = data.aws_iam_policy_document.staging_bucket_kms.json
  tags                    = local.tags
}

resource "aws_kms_alias" "staging_bucket" {
  name          = "alias/${local.application_name}-staging-bucket"
  target_key_id = aws_kms_key.staging_bucket.key_id
}

resource "aws_s3_bucket" "staging_bucket" {
  bucket_prefix = "${local.application_name}-staging-bucket-"
  tags          = local.tags
}

resource "aws_s3_bucket_versioning" "staging_bucket" {
  bucket = aws_s3_bucket.staging_bucket.id

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_ownership_controls" "staging_bucket" {
  bucket = aws_s3_bucket.staging_bucket.id

  rule {
    object_ownership = "BucketOwnerEnforced"
  }
}

resource "aws_s3_bucket_public_access_block" "staging_bucket" {
  bucket = aws_s3_bucket.staging_bucket.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_server_side_encryption_configuration" "staging_bucket" {
  bucket = aws_s3_bucket.staging_bucket.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm     = "aws:kms"
      kms_master_key_id = aws_kms_key.staging_bucket.arn
    }
  }
}

resource "aws_s3_bucket_lifecycle_configuration" "staging_bucket" {
  bucket = aws_s3_bucket.staging_bucket.id

  rule {
    id     = "abort-incomplete-multipart-uploads"
    status = "Enabled"

    filter {
      prefix = ""
    }

    abort_incomplete_multipart_upload {
      days_after_initiation = 7
    }
  }
}

data "aws_iam_policy_document" "staging_bucket" {
  statement {
    sid     = "DenyInsecureTransport"
    effect  = "Deny"
    actions = ["s3:*"]
    resources = [
      aws_s3_bucket.staging_bucket.arn,
      "${aws_s3_bucket.staging_bucket.arn}/*",
    ]

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

  dynamic "statement" {
    for_each = length(local.ecs_task_roles) > 0 ? [local.ecs_task_roles] : []

    content {
      sid    = "AllowAccountECSTaskRoles"
      effect = "Allow"
      actions = [
        "s3:GetBucketLocation",
        "s3:ListBucket",
        "s3:GetObject",
        "s3:PutObject",
      ]
      resources = [
        aws_s3_bucket.staging_bucket.arn,
        "${aws_s3_bucket.staging_bucket.arn}/*",
      ]

      principals {
        type        = "AWS"
        identifiers = [for role in local.ecs_task_roles : role.arn]
      }

      condition {
        test     = "StringEquals"
        variable = "aws:PrincipalAccount"
        values   = [data.aws_caller_identity.current.account_id]
      }
    }
  }
}

resource "aws_s3_bucket_policy" "staging_bucket" {
  bucket = aws_s3_bucket.staging_bucket.id
  policy = data.aws_iam_policy_document.staging_bucket.json

  depends_on = [aws_s3_bucket_public_access_block.staging_bucket]
}

data "aws_iam_policy_document" "ecs_staging_bucket_kms" {
  statement {
    effect    = "Allow"
    actions   = ["kms:Decrypt", "kms:GenerateDataKey"]
    resources = [aws_kms_key.staging_bucket.arn]

    condition {
      test     = "StringEquals"
      variable = "aws:PrincipalAccount"
      values   = [data.aws_caller_identity.current.account_id]
    }

    condition {
      test     = "StringEquals"
      variable = "kms:ViaService"
      values   = ["s3.${data.aws_region.current.region}.amazonaws.com"]
    }

    condition {
      test     = "StringLike"
      variable = "kms:EncryptionContext:aws:s3:arn"
      values   = [aws_s3_bucket.staging_bucket.arn, "${aws_s3_bucket.staging_bucket.arn}/*"]
    }
  }
}

resource "aws_iam_role_policy" "ecs_staging_bucket_kms" {
  for_each = local.ecs_task_roles

  name   = "${local.application_name}-ecs-staging-bucket-kms"
  role   = each.value.name
  policy = data.aws_iam_policy_document.ecs_staging_bucket_kms.json
}
