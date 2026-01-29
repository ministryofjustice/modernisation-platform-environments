# Main S3 bucket, that is replicated from (rather than to)
# KMS Encryption handled by aws_s3_bucket_server_side_encryption_configuration resource
# Logging handled by aws_s3_bucket_logging resource
# Versioning handled by aws_s3_bucket_versioning resource
# tfsec:ignore:aws-s3-enable-bucket-encryption tfsec:ignore:aws-s3-encryption-customer-key tfsec:ignore:aws-s3-enable-bucket-logging tfsec:ignore:aws-s3-enable-versioning
resource "aws_s3_bucket" "default" {
  #checkov:skip=CKV_AWS_144: "Replication handled in replication configuration resource"
  #checkov:skip=CKV_AWS_18: "Logging handled in logging configuration resource"
  #checkov:skip=CKV_AWS_21: "Versioning handled in Versioning configuration resource"
  #checkov:skip=CKV_AWS_145: "Encryption handled in encryption configuration resource"

  bucket_prefix = "${var.local_bucket_prefix}-manifest-${var.data_feed}-${var.order_type}-"

  tags = var.local_tags
}

resource "aws_s3_bucket_ownership_controls" "default" {
  bucket = aws_s3_bucket.default.id
  rule {
    object_ownership = "BucketOwnerEnforced"
  }
}

# Configure bucket ACL
resource "aws_s3_bucket_acl" "default" {
  bucket = aws_s3_bucket.default.id
  acl    = "private"
  depends_on = [
    aws_s3_bucket_ownership_controls.default
  ]
}



# Block public access policies for this bucket
resource "aws_s3_bucket_public_access_block" "default" {
  bucket                  = aws_s3_bucket.default.bucket
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# Merge and attach policies to the S3 bucket
# This ensures every bucket created via this module
# doesn't allow any actions that aren't over SecureTransport methods (i.e. HTTP)
resource "aws_s3_bucket_policy" "default" {
  bucket = aws_s3_bucket.default.id
  policy = data.aws_iam_policy_document.default.json

  # Create the Public Access Block before the policy is added
  depends_on = [aws_s3_bucket_public_access_block.default]
}

resource "aws_s3_bucket_versioning" "default" {
  bucket = aws_s3_bucket.default.id
  versioning_configuration {
    status = "Enabled"
  }
}


data "aws_iam_policy_document" "default" {

  statement {
    sid     = "EnforceTLSv12orHigher"
    effect  = "Deny"
    actions = ["s3:*"]
    resources = [
      aws_s3_bucket.default.arn,
      "${aws_s3_bucket.default.arn}/*"
    ]
    principals {
      identifiers = ["*"]
      type        = "AWS"
    }
    condition {
      test     = "NumericLessThan"
      variable = "s3:TlsVersion"
      values   = [1.2]
    }
  }
}


