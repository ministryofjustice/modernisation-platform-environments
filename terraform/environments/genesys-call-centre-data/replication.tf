locals {
  replication_bucket = "arn:aws:s3:::${var.replication_bucket}/*"
}

data "aws_caller_identity" "current" {}

resource "aws_s3_bucket_notification" "bucket_notification_replication" {
  count    = var.replication_enabled && var.notification_enabled ? 1 : 0
  provider = aws.bucket-replication
  bucket   = aws_s3_bucket.replication[count.index]

  topic {
    topic_arn = var.notification_sns_arn
    events    = var.notification_events
  }
}
# Replication S3 bucket, to replicate to (rather than from)
# Logging not deemed required for replication bucket
# tfsec:ignore:aws-s3-enable-bucket-logging
resource "aws_s3_bucket" "replication" {
  count         = var.replication_enabled ? 1 : 0
  provider      = aws.bucket-replication
  bucket        = var.bucket_name != null ? "${var.bucket_name}-replication" : null
  bucket_prefix = var.bucket_prefix != null ? "${var.bucket_prefix}-replication" : null
  force_destroy = var.force_destroy
  tags          = var.tags
}

resource "aws_s3_bucket_ownership_controls" "replication" {
  count    = var.replication_enabled ? 1 : 0
  provider = aws.bucket-replication
  bucket   = aws_s3_bucket.replication[0].id
  rule {
    object_ownership = var.ownership_controls
  }
}

# Configure bucket ACL
resource "aws_s3_bucket_acl" "replication" {
  count = var.replication_enabled && var.ownership_controls != "BucketOwnerEnforced" ? 1 : 0

  provider = aws.bucket-replication
  bucket   = length(aws_s3_bucket.replication) > 0 ? aws_s3_bucket.replication[0].id : ""
  acl      = var.acl
  depends_on = [
    aws_s3_bucket_ownership_controls.replication
  ]
}

# Configure bucket lifecycle rules

resource "aws_s3_bucket_lifecycle_configuration" "replication" {
  #checkov:skip=CKV_AWS_300: "Ensure S3 lifecycle configuration sets period for aborting failed uploads"
  count    = var.replication_enabled ? 1 : 0
  provider = aws.bucket-replication
  bucket   = aws_s3_bucket.replication[count.index].id
  rule {
    id     = "main"
    status = "Enabled"

    transition {
      days          = 90
      storage_class = "STANDARD_IA"
    }

    transition {
      days          = 365
      storage_class = "GLACIER"
    }

    expiration {
      days = 730
    }

    noncurrent_version_transition {
      noncurrent_days = 90
      storage_class   = "STANDARD_IA"
    }

    noncurrent_version_transition {
      noncurrent_days = 365
      storage_class   = "GLACIER"
    }

    noncurrent_version_expiration {
      noncurrent_days = 730
    }
  }
}

# Block public access policies to the replication bucket
resource "aws_s3_bucket_public_access_block" "replication" {
  count = var.replication_enabled ? 1 : 0

  provider                = aws.bucket-replication
  bucket                  = aws_s3_bucket.replication[count.index].bucket
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# Attach policies to the S3 bucket
# This ensures every bucket created via this module
# doesn't allow any actions that aren't over SecureTransport methods (i.e. HTTP)
resource "aws_s3_bucket_policy" "replication" {
  count = var.replication_enabled ? 1 : 0

  provider = aws.bucket-replication
  bucket   = aws_s3_bucket.replication[count.index].id
  policy   = data.aws_iam_policy_document.replication[count.index].json

  # Create the Public Access Block before the policy is added
  depends_on = [aws_s3_bucket_public_access_block.replication]
}

resource "aws_s3_bucket_server_side_encryption_configuration" "replication" {
  #checkov:skip=CKV2_AWS_67: "Ensure AWS S3 bucket encrypted with Customer Managed Key (CMK) has regular rotation"
  count = var.replication_enabled ? 1 : 0

  provider = aws.bucket-replication
  bucket   = aws_s3_bucket.replication[count.index].id
  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm     = var.sse_algorithm
      kms_master_key_id = (var.custom_replication_kms_key != "") ? var.custom_replication_kms_key : ""
    }
  }
}

resource "aws_s3_bucket_versioning" "replication" {
  count = var.replication_enabled ? 1 : 0

  provider = aws.bucket-replication
  bucket   = aws_s3_bucket.replication[count.index].id
  versioning_configuration {
    status = "Enabled"
  }
}

data "aws_iam_policy_document" "replication" {
  count    = var.replication_enabled ? 1 : 0
  provider = aws.bucket-replication

  statement {
    effect  = "Deny"
    actions = ["s3:*"]
    resources = [
      aws_s3_bucket.replication[count.index].arn,
      "${aws_s3_bucket.replication[count.index].arn}/*"
    ]

    principals {
      identifiers = ["*"]
      type        = "AWS"
    }

    condition {
      test     = "Bool"
      variable = "aws:SecureTransport"
      values   = ["false"]
    }
  }

}

# S3 bucket replication: role
resource "aws_iam_role" "replication_role" {
  provider           = aws.bucket-replication
  count              = var.replication_enabled ? 1 : 0
  name               = "AWSS3BucketReplication${var.suffix_name}"
  assume_role_policy = data.aws_iam_policy_document.s3-assume-role-policy.json
  tags               = var.tags
}


# S3 bucket replication: assume role policy
data "aws_iam_policy_document" "s3-assume-role-policy" {
  version = "2012-10-17"
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["s3.amazonaws.com"]
    }
  }
}
resource "aws_iam_policy" "replication_policy" {
  # name = "AWSS3BucketReplicatioPolicy${var.suffix_name}"
  count    = var.replication_enabled ? 1 : 0
  provider = aws.bucket-replication
  name     = "AWSS3BucketReplication${var.suffix_name}"
  policy   = data.aws_iam_policy_document.replication-policy.json
}

# S3 bucket replication: role policy
# tfsec:ignore:aws-iam-no-policy-wildcards
data "aws_iam_policy_document" "replication-policy" {
  version = "2012-10-17"
  statement {
    effect = "Allow"
    actions = [
      "s3:GetReplicationConfiguration",
      "s3:ListBucket"

    ]
    resources = [aws_s3_bucket.default.arn]
  }

  statement {
    effect = "Allow"
    actions = [
      "s3:GetObjectVersion",
      "s3:GetObjectVersionAcl",
      "s3:GetObjectVersionForReplication",
      "s3:GetObjectLegalHold",
      "s3:GetObjectRetention",
      "s3:GetObjectVersionTagging"
    ]
    resources = ["${aws_s3_bucket.default.arn}/*"]
  }

  statement {
    effect = "Allow"
    actions = [
      "s3:ReplicateObject",
      "s3:ReplicateDelete",
      "s3:ReplicateTags",
      "s3:GetObjectVersionTagging",
      "s3:ObjectOwnerOverrideToBucketOwner"
    ]

    resources = [var.replication_bucket != "" ? local.replication_bucket : "*"]



    condition {
      test     = "StringLikeIfExists"
      variable = "s3:x-amz-server-side-encryption"
      values = [
        "aws:kms",
        "AES256"
      ]
    }
  }
}

resource "aws_iam_role_policy_attachment" "replication" {
  count      = var.replication_enabled ? 1 : 0
  provider   = aws.bucket-replication
  role       = aws_iam_role.replication_role[count.index].name
  policy_arn = aws_iam_policy.replication_policy[count.index].arn
}

resource "aws_s3_bucket_replication_configuration" "default" {
  for_each = var.replication_enabled ? toset(["run"]) : []
  bucket   = aws_s3_bucket.default.id
  role     = aws_iam_role.replication_role[0].arn
  rule {
    id       = "SourceToDestinationReplication"
    status   = var.replication_enabled ? "Enabled" : "Disabled"
    priority = 0

    destination {
      bucket        = var.replication_enabled ? aws_s3_bucket.replication[0].arn : aws_s3_bucket.replication[0].arn
      storage_class = "STANDARD"
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