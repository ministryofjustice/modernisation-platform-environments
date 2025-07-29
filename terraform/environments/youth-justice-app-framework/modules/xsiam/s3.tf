### XSIAM FIREHOSE ###

resource "aws_s3_bucket" "firehose_backup_xsiam" {
  # checkov:skip=CKV2_AWS_62
  # checkov:skip=CKV_AWS_144
  bucket = "yjaf-${var.environment}-firehose-xsiam-backup"
}

resource "aws_s3_bucket_public_access_block" "firehose_backup_xsiam_block" {
  bucket = aws_s3_bucket.firehose_backup_xsiam.id

  block_public_acls       = true
  ignore_public_acls      = true
  block_public_policy     = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_versioning" "firehose_backup_xsiam_versioning" {
  bucket = aws_s3_bucket.firehose_backup_xsiam.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_lifecycle_configuration" "firehose_backup_xsiam_lifecycle" {
  bucket = aws_s3_bucket.firehose_backup_xsiam.id

  rule {
    id     = "expire-old-logs"
    status = "Enabled"

    filter {
      prefix = ""
    }

    expiration {
      days = 400
    }

    abort_incomplete_multipart_upload {
      days_after_initiation = 7
    }
  }
}

resource "aws_s3_bucket_logging" "firehose_backup_xsiam_logging" {
  bucket = aws_s3_bucket.firehose_backup_xsiam.id

  target_bucket = "yjaf-${var.environment}-firehose-xsiam-backup"
  target_prefix = "firehose-backup-logs/"
}

resource "aws_s3_bucket_server_side_encryption_configuration" "firehose_backup_xsiam_encryption" {
  bucket = aws_s3_bucket.firehose_backup_xsiam.id

  rule {
    apply_server_side_encryption_by_default {
      kms_master_key_id = aws_kms_key.firehose_backup_xsiam.arn
      sse_algorithm     = "aws:kms"
    }
  }
}