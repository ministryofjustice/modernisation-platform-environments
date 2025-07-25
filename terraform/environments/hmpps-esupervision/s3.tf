resource "aws_s3_bucket" "rekognition_bucket" {
  bucket = local.rekog_s3_bucket_name
}

resource "aws_kms_key" "rekognition_encryption_key" {
  description             = "Encryption key for rekognition image uploads bucket"
  deletion_window_in_days = 30
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