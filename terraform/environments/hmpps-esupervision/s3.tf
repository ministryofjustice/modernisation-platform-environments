resource "aws_s3_bucket" "rekognition_bucket" {
  bucket = local.rekog_s3_bucket_name
}

resource "aws_s3_bucket_cors_configuration" "rekognition_bucket_cors" {
  bucket = aws_s3_bucket.rekognition_bucket.id

  cors_rule {
    allowed_headers = ["*"]
    allowed_methods = ["GET", "PUT"]
    // TODO: restrict to known environments
    // need to allow for dev
    allowed_origins = ["*"]
    expose_headers  = ["ETag"]
    max_age_seconds = 3000
  }
}

resource "aws_kms_key" "rekognition_encryption_key" {
  description             = "Encryption key for rekognition image uploads bucket"
  deletion_window_in_days = 30
}

data "aws_iam_policy_document" "rekognition_kms_key_policy" {
  # NOTE: this is the default key policy granting root user access
  statement {
    sid    = "DefaultKeyPolicy"
    effect = "Allow"
    principals {
      identifiers = ["arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"]
      type        = "AWS"
    }
    actions   = ["kms:*"]
    resources = ["*"]
  }

  # Allow access to rekognition role
  statement {
    sid    = "RekognitionRoleKeyUser"
    effect = "Allow"
    principals {
      identifiers = [aws_iam_role.rekognition_role.arn]
      type        = "AWS"
    }
    actions = [
      "kms:Decrypt",
      "kms:DescribeKey",
      "kms:Encrypt",
      "kms:GenerateDataKey*",
      "kms:ReEncrypt*"
    ]
    resources = ["*"]
  }
}

resource "aws_kms_key_policy" "rekognition_encryption_key_policy" {
  key_id = aws_kms_key.rekognition_encryption_key.id
  policy = data.aws_iam_policy_document.rekognition_kms_key_policy.json
}

resource "aws_s3_bucket_server_side_encryption_configuration" "rekognition_bucket_encryption_configuration" {
  bucket = aws_s3_bucket.rekognition_bucket.id

  rule {
    bucket_key_enabled = true
    apply_server_side_encryption_by_default {
      kms_master_key_id = aws_kms_key.rekognition_encryption_key.arn
      sse_algorithm     = "aws:kms"
    }
  }
}

resource "aws_s3_bucket_public_access_block" "rekognition_bucket_policy" {
  bucket                  = aws_s3_bucket.rekognition_bucket.id
  block_public_policy     = true
  block_public_acls       = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}