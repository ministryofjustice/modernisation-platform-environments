#------------------------------------------------------------------------------
# S3 bucket for data store logs
#------------------------------------------------------------------------------

module "data_store_log_bucket" {
  source = "./modules/s3_log_bucket"

  source_bucket = aws_s3_bucket.data_store
  account_id    = data.aws_caller_identity.current.account_id
}

#------------------------------------------------------------------------------
# S3 bucket for landed data (internal facing)
#------------------------------------------------------------------------------

resource "aws_s3_bucket" "data_store" {
  bucket_prefix = "em-data-store-"
}

resource "aws_s3_bucket_server_side_encryption_configuration" "data_store" {
  bucket = aws_s3_bucket.data_store.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_public_access_block" "data_store" {
  bucket                  = aws_s3_bucket.data_store.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_versioning" "data_store" {
  bucket = aws_s3_bucket.data_store.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_logging" "data_store" {
  bucket = aws_s3_bucket.data_store.id

  target_bucket = module.data_store_log_bucket.bucket_id
  target_prefix = "log/"

  target_object_key_format {
    partitioned_prefix {
      partition_date_source = "EventTime"
    }
  }
}
