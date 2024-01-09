#------------------------------------------------------------------------------
# S3 bucket for bucket access logs
#------------------------------------------------------------------------------

resource "aws_s3_bucket" "log_bucket" {
  bucket = "my-tf-log-bucket"
}

resource "aws_s3_bucket_acl" "log_bucket_acl" {
  bucket = aws_s3_bucket.log_bucket.id
  acl    = "log-delivery-write"
}

#------------------------------------------------------------------------------
# S3 bucket for Capita
#------------------------------------------------------------------------------

resource "aws_s3_bucket" "capita_landing_bucket" {
  bucket_prefix = "capita"
}

resource "aws_s3_bucket_acl" "capita_landing_bucket" {
  bucket = aws_s3_bucket.capita_landing_bucket.id
  acl    = "private"
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