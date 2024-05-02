resource "aws_s3_bucket" "athena_iceberg_s3_bucket" {
  bucket_prefix = "em-athena-iceberg-"

  tags = merge(
    local.tags,
    {
      Resource_Type = "S3 Bucket for Athena Iceberg Tables",
    }
  )
}

resource "aws_s3_bucket_public_access_block" "athena_iceberg_s3_bucket" {
  bucket                  = aws_s3_bucket.athena_iceberg_s3_bucket.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_server_side_encryption_configuration" "athena_iceberg_s3_bucket" {
  bucket = aws_s3_bucket.athena_iceberg_s3_bucket.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_policy" "athena_iceberg_s3_bucket" {
  bucket = aws_s3_bucket.athena_iceberg_s3_bucket.id
  policy = data.aws_iam_policy_document.dms_target_ep_s3_bucket.json
}
