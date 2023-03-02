resource "aws_s3_bucket" "wepi_redshift_logging_bucket" {
  #checkov:skip=CKV_AWS_144: "Cross-region replication is not required"
  #checkov:skip=CKV_AWS_18:  "Bucket access logging is not required"
  #checkov:skip=CKV_AWS_21:  "Bucket versioning is not required"
  bucket = "wepi-redshift-logs-${local.environment}"
}

resource "aws_s3_bucket_acl" "wepi_redshift_logging_bucket_acl" {
  bucket = aws_s3_bucket.wepi_redshift_logging_bucket.bucket
  acl    = "private"
}

resource "aws_s3_bucket_lifecycle_configuration" "wepi_redshift_logging_bucket_lifecycle" {
  bucket = aws_s3_bucket.wepi_redshift_logging_bucket.bucket

  rule {
    id = "expiry"

    expiration {
      days = local.application_data.accounts[local.environment].redshift_log_retention
    }

    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "wepi_redshift_logging_bucket_enc" {
  bucket = aws_s3_bucket.wepi_redshift_logging_bucket.bucket

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm     = "aws:kms"
      kms_master_key_id = aws_kms_key.wepi_kms_cmk.arn
    }
  }
}

resource "aws_s3_bucket_public_access_block" "wepi_redshift_logging_bucket_public_access_block" {
  bucket                  = aws_s3_bucket.wepi_redshift_logging_bucket.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_policy" "wepi_redshift_logging_bucket_policy" {
  depends_on = [
    aws_s3_bucket_public_access_block.wepi_redshift_logging_bucket_public_access_block
  ]
  bucket = aws_s3_bucket.wepi_redshift_logging_bucket.id
  policy = templatefile("${path.module}/json/wepi_s3_policy_redshift_logging.json",
    {
      bucket_arn = aws_s3_bucket.wepi_redshift_logging_bucket.arn
    }
  )
}
