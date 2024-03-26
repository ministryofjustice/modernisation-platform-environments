resource "aws_s3_bucket" "ap_export_bucket" {
    bucket_prefix = "ap-export-bucket-"
}

resource "aws_s3_bucket_public_access_block" "ap_export_bucket" {
  bucket                  = aws_s3_bucket.ap_export_bucket.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_versioning" "ap_export_bucket" {
  bucket = aws_s3_bucket.ap_export_bucket.id
  versioning_configuration {
    status = "Enabled"
  }
}

data "aws_iam_policy_document" "ap_export_bucket" {
  statement {
    sid = "EnforceTLSv12orHigher"
    principals {
      type        = "AWS"
      identifiers = ["*"]
    }
    effect  = "Deny"
    actions = ["s3:*"]
    resources = [
      aws_s3_bucket.ap_export_bucket.arn,
      "${aws_s3_bucket.ap_export_bucket.arn}/*"
    ]
    condition {
      test     = "NumericLessThan"
      variable = "s3:TlsVersion"
      values   = [1.2]
    }
  }
}

module "ap_export_log_bucket" {
  source = "./modules/s3_log_bucket"

  source_bucket = aws_s3_bucket.ap_export_bucket
  account_id    = data.aws_caller_identity.current.account_id
  local_tags    = local.tags

}


resource "aws_s3_bucket_logging" "ap_export_bucket" {
  bucket = aws_s3_bucket.ap_export_bucket.id

  target_bucket = module.ap_export_log_bucket.bucket_id
  target_prefix = "log/"

  target_object_key_format {
    partitioned_prefix {
      partition_date_source = "EventTime"
    }
  }
}