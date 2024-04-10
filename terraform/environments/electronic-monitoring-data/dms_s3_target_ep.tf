resource "aws_s3_bucket" "dms_target_ep_s3_bucket" {
  bucket_prefix = "dms-rds-to-parquet-"

  tags = merge(
    local.tags,
    {
      Resource_Type = "DMS Target Endpoint S3 Bucket",
    }
  )
}

resource "aws_s3_bucket_public_access_block" "dms_target_ep_s3_bucket" {
  bucket                  = aws_s3_bucket.dms_target_ep_s3_bucket.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_server_side_encryption_configuration" "dms_target_ep_s3_bucket" {
  bucket = aws_s3_bucket.dms_target_ep_s3_bucket.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_policy" "dms_target_ep_s3_bucket" {
  bucket = aws_s3_bucket.dms_target_ep_s3_bucket.id
  policy = data.aws_iam_policy_document.dms_target_ep_s3_bucket.json
}
