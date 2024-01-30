#------------------------------------------------------------------------------
# S3 bucket for bucket action logs
#------------------------------------------------------------------------------

resource "aws_s3_bucket" "log_bucket" {
  bucket_prefix = "em-data-store-logs-"
  force_destroy = true
}

resource "aws_s3_bucket_server_side_encryption_configuration" "log_bucket" {
  bucket = aws_s3_bucket.log_bucket.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_public_access_block" "log_bucket" {
  bucket                  = aws_s3_bucket.log_bucket.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_acl" "log_bucket_acl" {
  bucket = aws_s3_bucket.log_bucket.id
  acl    = "log-delivery-write"
}

#------------------------------------------------------------------------------
# S3 bucket for landed data (internal facing)
#------------------------------------------------------------------------------

resource "aws_s3_bucket" "data_store_bucket" {
  bucket_prefix = "em-data-store-"
}

resource "aws_s3_bucket_server_side_encryption_configuration" "data_store_bucket" {
  bucket = aws_s3_bucket.data_store_bucket.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_public_access_block" "data_store_bucket" {
  bucket                  = aws_s3_bucket.data_store_bucket.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_versioning" "data_store" {
  bucket = aws_s3_bucket.data_store_bucket.id
  versioning_configuration {
    status = "Enabled"
  }
}
