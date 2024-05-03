module "unzipped_store_log_bucket" {
  source = "./modules/s3_log_bucket"

  source_bucket = aws_s3_bucket.unzipped_store
  account_id    = data.aws_caller_identity.current.account_id
  local_tags    = local.tags
}

resource "aws_s3_bucket" "unzipped_store" {
  bucket_prefix = "em-data-store-"

  tags = local.tags
}

resource "aws_s3_bucket_server_side_encryption_configuration" "unzipped_store" {
  bucket = aws_s3_bucket.unzipped_store.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_public_access_block" "unzipped_store" {
  bucket                  = aws_s3_bucket.unzipped_store.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_versioning" "unzipped_store" {
  bucket = aws_s3_bucket.unzipped_store.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_policy" "unzipped_store" {
  bucket = aws_s3_bucket.unzipped_store.id
  policy = data.aws_iam_policy_document.unzipped_store.json
}

data "aws_iam_policy_document" "unzipped_store" {
  statement {
    sid = "EnforceTLSv12orHigher"
    principals {
      type        = "AWS"
      identifiers = ["*"]
    }
    effect  = "Deny"
    actions = ["s3:*"]
    resources = [
      aws_s3_bucket.unzipped_store.arn,
      "${aws_s3_bucket.unzipped_store.arn}/*"
    ]
    condition {
      test     = "NumericLessThan"
      variable = "s3:TlsVersion"
      values   = [1.2]
    }
  }
}

resource "aws_s3_bucket_logging" "unzipped_store" {
  bucket = aws_s3_bucket.unzipped_store.id

  target_bucket = module.unzipped_store_log_bucket.bucket_id
  target_prefix = "log/"

  target_object_key_format {
    partitioned_prefix {
      partition_date_source = "EventTime"
    }
  }
}