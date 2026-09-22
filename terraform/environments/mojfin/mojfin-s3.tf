resource "aws_s3_bucket" "mojfin_rds_oracle" {
  bucket = "mojfin-oracle-rds-${local.environment}"
}

data "aws_iam_policy_document" "mojfin_rds_oracle_secure_transport" {
  statement {
    sid    = "DenyInsecureTransport"
    effect = "Deny"
    principals {
      type        = "*"
      identifiers = ["*"]
    }
    actions = ["s3:*"]
    resources = [
      aws_s3_bucket.mojfin_rds_oracle.arn,
      "${aws_s3_bucket.mojfin_rds_oracle.arn}/*",
    ]
    condition {
      test     = "Bool"
      variable = "aws:SecureTransport"
      values   = ["false"]
    }
  }
}

resource "aws_s3_bucket_policy" "mojfin_rds_oracle_secure_transport" {
  bucket = aws_s3_bucket.mojfin_rds_oracle.id
  policy = data.aws_iam_policy_document.mojfin_rds_oracle_secure_transport.json
}

resource "aws_s3_bucket_logging" "mojfin_rds_oracle" {
  bucket        = aws_s3_bucket.mojfin_rds_oracle.id
  target_bucket = module.s3-bucket-logging.bucket.id
  target_prefix = "log/"
  target_object_key_format {
    partitioned_prefix {
      partition_date_source = "EventTime"
    }
  }
}