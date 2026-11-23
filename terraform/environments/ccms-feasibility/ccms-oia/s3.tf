# Shared S3 server access logs bucket, managed in ccms-feasibility root
data "aws_s3_bucket" "s3_access_logs" {
  bucket = "${local.application_name}-s3-access-logs"
}

resource "aws_s3_bucket" "connector_docs" {
  bucket = "${local.component_name}-${local.env_label}-docs"

  tags = merge(local.tags, {
    Name = "${local.component_name}-${local.env_label}-docs"
  })
}

resource "aws_s3_bucket_logging" "connector_docs" {
  bucket        = aws_s3_bucket.connector_docs.id
  target_bucket = data.aws_s3_bucket.s3_access_logs.id
  target_prefix = "${aws_s3_bucket.connector_docs.id}/"

  target_object_key_format {
    partitioned_prefix {
      partition_date_source = "EventTime"
    }
  }
}

resource "aws_s3_bucket_versioning" "connector_docs" {
  bucket = aws_s3_bucket.connector_docs.id

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "connector_docs" {
  bucket = aws_s3_bucket.connector_docs.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_public_access_block" "connector_docs" {
  bucket                  = aws_s3_bucket.connector_docs.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_policy" "connector_docs" {
  bucket = aws_s3_bucket.connector_docs.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid       = "DenyInsecureTransport"
        Effect    = "Deny"
        Principal = "*"
        Action    = "s3:*"
        Resource = [
          aws_s3_bucket.connector_docs.arn,
          "${aws_s3_bucket.connector_docs.arn}/*",
        ]
        Condition = {
          Bool = { "aws:SecureTransport" = "false" }
        }
      },
      {
        Sid       = "DenyTLSOlderThan12"
        Effect    = "Deny"
        Principal = "*"
        Action    = "s3:*"
        Resource = [
          aws_s3_bucket.connector_docs.arn,
          "${aws_s3_bucket.connector_docs.arn}/*",
        ]
        Condition = {
          NumericLessThan = { "s3:TlsVersion" = "1.2" }
        }
      },
    ]
  })

  depends_on = [aws_s3_bucket_public_access_block.connector_docs]
}
