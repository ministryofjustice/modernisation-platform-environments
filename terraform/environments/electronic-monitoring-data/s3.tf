#------------------------------------------------------------------------------
# S3 bucket for bucket action logs
#------------------------------------------------------------------------------

resource "aws_s3_bucket" "log_bucket" {
  bucket_prefix = "em-data-store-logs-"
  force_destroy = true
}

# resource "aws_s3_bucket_acl" "log_bucket_acl" {
#   bucket = aws_s3_bucket.log_bucket.id
#   acl    = "log-delivery-write"
# }

#------------------------------------------------------------------------------
# S3 bucket for landing Capita data
#
# Lifecycle management not implemented for this bucket as everything will be
# moved to a different bucket once landed.
#------------------------------------------------------------------------------

resource "random_string" "capita" {
  length  = 10
  lower   = true
  upper   = false
  numeric = true
  special = false
}

resource "aws_s3_bucket" "capita_landing_bucket" {
  bucket = "capita-${random_string.capita.result}"
}

resource "aws_s3_bucket_policy" "capita_landing_bucket_policy" {
  bucket = aws_s3_bucket.capita_landing_bucket.id
  policy = data.aws_iam_policy_document.capita_landing_bucket.json
}

data "aws_iam_policy_document" "capita_landing_bucket" {
  statement {
    sid = "EnforceTLSv12orHigher"
    principals {
      type        = "AWS"
      identifiers = ["*"]
    }
    effect  = "Deny"
    actions = ["s3:*"]
    resources = [
      aws_s3_bucket.capita_landing_bucket.arn,
      "${aws_s3_bucket.capita_landing_bucket.arn}/*"
    ]
    condition {
      test     = "NumericLessThan"
      variable = "s3:TlsVersion"
      values   = [1.2]
    }
  }
}

resource "aws_s3_bucket_versioning" "capita" {
  bucket = aws_s3_bucket.capita_landing_bucket.id
  versioning_configuration {
    status = "Disabled"
  }
}

resource "aws_s3_bucket_logging" "capita" {
  bucket = aws_s3_bucket.capita_landing_bucket.id

  target_bucket = aws_s3_bucket.log_bucket.id
  target_prefix = "log/"

  target_object_key_format {
    partitioned_prefix {
      partition_date_source = "EventTime"
    }
  }
}

#------------------------------------------------------------------------------
# S3 bucket for landing Civica data
#
# Lifecycle management not implemented for this bucket as everything will be
# moved to a different bucket once landed.
#------------------------------------------------------------------------------

resource "random_string" "civica" {
  length  = 10
  lower   = true
  upper   = false
  numeric = true
  special = false
}

resource "aws_s3_bucket" "civica_landing_bucket" {
  bucket = "civica-${random_string.civica.result}"
}

resource "aws_s3_bucket_policy" "civica_landing_bucket_policy" {
  bucket = aws_s3_bucket.civica_landing_bucket.id
  policy = data.aws_iam_policy_document.civica_landing_bucket.json
}

data "aws_iam_policy_document" "civica_landing_bucket" {
  statement {
    sid = "EnforceTLSv12orHigher"
    principals {
      type        = "AWS"
      identifiers = ["*"]
    }
    effect  = "Deny"
    actions = ["s3:*"]
    resources = [
      aws_s3_bucket.civica_landing_bucket.arn,
      "${aws_s3_bucket.civica_landing_bucket.arn}/*"
    ]
    condition {
      test     = "NumericLessThan"
      variable = "s3:TlsVersion"
      values   = [1.2]
    }
  }
}

resource "aws_s3_bucket_versioning" "civica" {
  bucket = aws_s3_bucket.civica_landing_bucket.id
  versioning_configuration {
    status = "Disabled"
  }
}

resource "aws_s3_bucket_logging" "civica" {
  bucket = aws_s3_bucket.civica_landing_bucket.id

  target_bucket = aws_s3_bucket.log_bucket.id
  target_prefix = "log/"

  target_object_key_format {
    partitioned_prefix {
      partition_date_source = "EventTime"
    }
  }
}

#------------------------------------------------------------------------------
# S3 bucket for landing G4S data
#
# Lifecycle management not implemented for this bucket as everything will be
# moved to a different bucket once landed.
#------------------------------------------------------------------------------

resource "random_string" "g4s" {
  length  = 10
  lower   = true
  upper   = false
  numeric = true
  special = false
}

resource "aws_s3_bucket" "g4s_landing_bucket" {
  bucket = "g4s-${random_string.g4s.result}"
}

resource "aws_s3_bucket_policy" "g4s_landing_bucket_policy" {
  bucket = aws_s3_bucket.g4s_landing_bucket.id
  policy = data.aws_iam_policy_document.g4s_landing_bucket.json
}

data "aws_iam_policy_document" "g4s_landing_bucket" {
  statement {
    sid = "EnforceTLSv12orHigher"
    principals {
      type        = "AWS"
      identifiers = ["*"]
    }
    effect  = "Deny"
    actions = ["s3:*"]
    resources = [
      aws_s3_bucket.g4s_landing_bucket.arn,
      "${aws_s3_bucket.g4s_landing_bucket.arn}/*"
    ]
    condition {
      test     = "NumericLessThan"
      variable = "s3:TlsVersion"
      values   = [1.2]
    }
  }
}

resource "aws_s3_bucket_versioning" "g4s" {
  bucket = aws_s3_bucket.g4s_landing_bucket.id
  versioning_configuration {
    status = "Disabled"
  }
}

resource "aws_s3_bucket_logging" "g4s" {
  bucket = aws_s3_bucket.g4s_landing_bucket.id

  target_bucket = aws_s3_bucket.log_bucket.id
  target_prefix = "log/"

  target_object_key_format {
    partitioned_prefix {
      partition_date_source = "EventTime"
    }
  }
}

#------------------------------------------------------------------------------
# S3 bucket for landed data (internal facing)
#------------------------------------------------------------------------------

resource "aws_s3_bucket" "data_store_bucket" {
  bucket_prefix = "em-data-store-"
}

resource "aws_s3_bucket_versioning" "data_store" {
  bucket = aws_s3_bucket.data_store_bucket.id
  versioning_configuration {
    status = "Enabled"
  }
}
