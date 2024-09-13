resource "aws_s3_bucket" "ems_mock_data_s3_bucket" {
  bucket_prefix = "ems-mock-data-"

  tags = merge(
    local.tags,
    {
      Resource_Type = "EMS semantic layer",
    }
  )
}

resource "aws_s3_bucket_public_access_block" "ems_mock_data_s3_bucket" {
  bucket                  = aws_s3_bucket.ems_mock_data_s3_bucket.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_server_side_encryption_configuration" "ems_mock_data_s3_bucket" {
  bucket = aws_s3_bucket.ems_mock_data_s3_bucket.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

data "aws_iam_policy_document" "ems_mock_data_s3_bucket" {
  statement {
    sid = "EnforceTLSv12orHigher"
    principals {
      type        = "AWS"
      identifiers = ["*"]
    }
    effect  = "Deny"
    actions = ["s3:*"]
    resources = [
      aws_s3_bucket.ems_mock_data_s3_bucket.arn,
      "${aws_s3_bucket.ems_mock_data_s3_bucket.arn}/*"
    ]
    condition {
      test     = "NumericLessThan"
      variable = "s3:TlsVersion"
      values   = [1.2]
    }
  }
}

resource "aws_s3_bucket_policy" "ems_mock_data_s3_bucket" {
  bucket = aws_s3_bucket.ems_mock_data_s3_bucket.id
  policy = data.aws_iam_policy_document.ems_mock_data_s3_bucket.json
}
