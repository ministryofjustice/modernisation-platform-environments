#####################################################################################
######################## S3 Bucket for Extracted Data ###############################
#####################################################################################

resource "aws_s3_bucket" "data" {
  bucket = "${local.application_name_short}-${local.environment}-cwa-extract-data"

  tags = merge(
    local.tags,
    { Name = "${local.application_name_short}-${local.environment}-cwa-extract-data" }
  )
}

resource "aws_s3_bucket_public_access_block" "data" {
  bucket                  = aws_s3_bucket.data.bucket
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_ownership_controls" "data" {
  bucket = aws_s3_bucket.data.id
  rule {
    object_ownership = "BucketOwnerEnforced"
  }
}

resource "aws_s3_bucket_versioning" "data" {
  bucket = aws_s3_bucket.data.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_logging" "data" {
  bucket = aws_s3_bucket.data.id

  target_bucket = aws_s3_bucket.access_logs.id
  target_prefix = "log/"
  target_object_key_format {
    partitioned_prefix {
      partition_date_source = "EventTime"
    }
  }
}

#####################################################################################
######################## S3 Bucket for Access Logs ###############################
#####################################################################################

resource "aws_s3_bucket" "access_logs" {
  bucket = "${local.application_name_short}-${local.environment}-s3-access-logs"

  tags = merge(
    local.tags,
    { Name = "${local.application_name_short}-${local.environment}-s3-access-logs" }
  )
}

resource "aws_s3_bucket_public_access_block" "access_logs" {
  bucket                  = aws_s3_bucket.access_logs.bucket
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_ownership_controls" "access_logs" {
  bucket = aws_s3_bucket.access_logs.id
  rule {
    object_ownership = "BucketOwnerEnforced"
  }
}

resource "aws_s3_bucket_versioning" "access_logs" {
  bucket = aws_s3_bucket.access_logs.id
  versioning_configuration {
    status = "Enabled"
  }
}


#####################################################################################
################# Logging for Lambda Files S3 bucket ###############################
#####################################################################################


resource "aws_s3_bucket_logging" "lambda_files" {
  # Bucket is managed in a separate Terraform state. We can still apply logging by
  # referencing the bucket name directly instead of a resource reference.
  bucket = "${local.application_name_short}-${local.environment}-lambda-files"

  target_bucket = aws_s3_bucket.access_logs.id
  target_prefix = "log/"
  target_object_key_format {
    partitioned_prefix {
      partition_date_source = "EventTime"
    }
  }
}
