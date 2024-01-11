#------------------------------------------------------------------------------
# S3 bucket for bucket action logs
#------------------------------------------------------------------------------

resource "aws_s3_bucket" "log_bucket" {
  bucket_prefix = "em-data-store-logs-"
}

resource "aws_s3_bucket_acl" "log_bucket_acl" {
  bucket = aws_s3_bucket.log_bucket.id
  acl    = "log-delivery-write"
}

#------------------------------------------------------------------------------
# S3 bucket for landing Capita data
#
# Lifecycle management not implemented for this bucket as everything will be
# moved to a different bucket once landed.
#------------------------------------------------------------------------------

resource "random_string" "capita_random_string" {
  length  = 10
  lower   = true
  upper   = false
  numeric = true
  special = false
}

resource "aws_s3_bucket" "capita_landing_bucket" {
  bucket = "capita-${random_string.capita_random_string.result}"
}

resource "aws_s3_bucket_versioning" "capita_landing_bucket" {
  bucket = aws_s3_bucket.capita_landing_bucket.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_logging" "capita_bucket_logging" {
  bucket = aws_s3_bucket.capita_landing_bucket.id

  target_bucket = aws_s3_bucket.log_bucket.id
  target_prefix = "log/"

  target_object_key_format {
    partitioned_prefix {
        partition_date_source = "EventTime"
    }
  }
}
