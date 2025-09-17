locals {
  bucket_name = "r2s-resources"
  genesys_aws_account_id = aws_secretsmanager_secret.genesys_aws_account_id.id
}

variable "genesys_external_id" {
  description = "Genesys Cloud organization ID"
  type        = string
  sensitive   = true
}

variable "snowflake_external_id" {
  description = "ExternalId to require when Snowflake assumes the Snowflake role."
  type        = string
  sensitive   = true
}

# Secret HANDLE only (value will be set manually in the console)
resource "aws_secretsmanager_secret" "genesys_aws_account_id" {
  name        = "genesys_aws_account_id" # you can also use "/r2s/genesys/aws_account_id"
  description = "Account ID for Genesys"
  tags        = local.tags
}

# --- S3 bucket ---

resource "aws_s3_bucket" "r2s" {
  bucket = local.bucket_name
  tags   = local.tags
}

# Public access blocked
resource "aws_s3_bucket_public_access_block" "r2s" {
  bucket                  = aws_s3_bucket.r2s.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# Ownership controls (helpful for cross-account uploads with ACLs)
resource "aws_s3_bucket_ownership_controls" "r2s" {
  bucket = aws_s3_bucket.r2s.id
  rule {
    object_ownership = "BucketOwnerPreferred"
  }
}

# Default encryption at rest (SSE-S3)
resource "aws_s3_bucket_server_side_encryption_configuration" "r2s" {
  bucket = aws_s3_bucket.r2s.id
  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

# Optional but recommended: require TLS in transit
data "aws_iam_policy_document" "r2s_tls_only" {
  statement {
    sid     = "DenyInsecureTransport"
    effect  = "Deny"
    actions = ["s3:*"]
    principals {
      type        = "*"
      identifiers = ["*"]
    }
    resources = [
      aws_s3_bucket.r2s.arn,
      "${aws_s3_bucket.r2s.arn}/*"
    ]
    condition {
      test     = "Bool"
      variable = "aws:SecureTransport"
      values   = ["false"]
    }
  }
}

resource "aws_s3_bucket_policy" "r2s" {
  bucket = aws_s3_bucket.r2s.id
  policy = data.aws_iam_policy_document.r2s_tls_only.json
}

# --- IAM: Genesys Cloud role & policy ---

# Policy with least-privilege per your instructions
data "aws_iam_policy_document" "genesys_policy_doc" {
  statement {
    sid     = "ObjectLevel"
    effect  = "Allow"
    actions = [
      "s3:PutObject",
      "s3:PutObjectAcl"
    ]
    resources = ["${aws_s3_bucket.r2s.arn}/*"]
  }

  statement {
    sid     = "BucketLevel"
    effect  = "Allow"
    actions = [
      "s3:GetBucketLocation",
      "s3:GetEncryptionConfiguration"
    ]
    resources = [aws_s3_bucket.r2s.arn]
  }
}

resource "aws_iam_policy" "genesys_policy" {
  name        = "r2s-genesys-upload"
  description = "Allow Genesys to put objects & read bucket location/encryption on ${local.bucket_name}"
  policy      = data.aws_iam_policy_document.genesys_policy_doc.json
  tags        = local.tags
}

# Trust: allow assume from Genesys account with ExternalId condition
data "aws_iam_policy_document" "genesys_trust" {
  statement {
    effect = "Allow"
    principals {
      type        = "AWS"
      identifiers = ["arn:aws:iam::${local.genesys_aws_account_id}:root"]
    }
    actions = ["sts:AssumeRole"]
    condition {
      test     = "StringEquals"
      variable = "sts:ExternalId"
      values   = [var.genesys_external_id]
    }
  }
}

resource "aws_iam_role" "genesys_role" {
  name               = "r2s-genesys-role"
  assume_role_policy = data.aws_iam_policy_document.genesys_trust.json
  description        = "Role assumed by Genesys Cloud export module to upload recordings to ${local.bucket_name}"
  tags               = locals.tags
}

resource "aws_iam_role_policy_attachment" "genesys_attach" {
  role       = aws_iam_role.genesys_role.name
  policy_arn = aws_iam_policy.genesys_policy.arn
}

# --- IAM: Snowflake role & policy ---

# Policy per your sample + steps (includes Put/Delete/Get/GetVersion/List + bucket info; also PutObjectAcl & GetEncryptionConfiguration as noted)
data "aws_iam_policy_document" "snowflake_policy_doc" {
  statement {
    sid     = "ObjectLevel"
    effect  = "Allow"
    actions = [
      "s3:PutObject",
      "s3:GetObject",
      "s3:GetObjectVersion",
      "s3:DeleteObject",
      "s3:PutObjectAcl"
    ]
    resources = ["${aws_s3_bucket.r2s.arn}/*"]
  }

  statement {
    sid     = "BucketLevel"
    effect  = "Allow"
    actions = [
      "s3:ListBucket",
      "s3:GetBucketLocation",
      "s3:GetEncryptionConfiguration"
    ]
    resources = [aws_s3_bucket.r2s.arn]
  }
}

resource "aws_iam_policy" "snowflake_policy" {
  name        = "r2s-snowflake-access"
  description = "Allow Snowflake (via integration assume-role) to access metadata objects in ${local.bucket_name}"
  policy      = data.aws_iam_policy_document.snowflake_policy_doc.json
  tags        = locals.tags
}

# Trust: pattern per your guide (same account + external ID). If Snowflake uses a different principal in your setup, swap the principal here.
data "aws_iam_policy_document" "snowflake_trust" {
  statement {
    effect = "Allow"
    principals {
      type        = "AWS"
      identifiers = ["arn:aws:iam::${local.genesys_aws_account_id}:root"]
    }
    actions = ["sts:AssumeRole"]
    condition {
      test     = "StringEquals"
      variable = "sts:ExternalId"
      values   = [var.snowflake_external_id]
    }
  }
}

resource "aws_iam_role" "snowflake_role" {
  name               = "r2s-snowflake-role"
  assume_role_policy = data.aws_iam_policy_document.snowflake_trust.json
  description        = "Role assumed for Snowflake processing to access metadata in ${local.bucket_name} (no recording-file access beyond object-level actions listed)"
  tags               = locals.tags
}

resource "aws_iam_role_policy_attachment" "snowflake_attach" {
  role       = aws_iam_role.snowflake_role.name
  policy_arn = aws_iam_policy.snowflake_policy.arn
}
